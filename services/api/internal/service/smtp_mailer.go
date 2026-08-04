package service

import (
	"context"
	"crypto/tls"
	"errors"
	"fmt"
	"io"
	"mime"
	"net"
	"net/mail"
	"net/smtp"
	"strings"
	"time"
)

type SMTPMailer struct {
	host      string
	port      int
	user      string
	password  string
	from      *mail.Address
	tlsConfig *tls.Config
}

func NewSMTPMailer(host string, port int, user, password, from string) (*SMTPMailer, error) {
	host = strings.TrimSpace(host)
	user = strings.TrimSpace(user)
	if host == "" || port < 1 || port > 65535 || user == "" || password == "" {
		return nil, errors.New("SMTP host, port, user, and password are required")
	}
	fromAddress, err := mail.ParseAddress(strings.TrimSpace(from))
	if err != nil {
		return nil, errors.New("SMTP_FROM must be a valid email address")
	}
	return &SMTPMailer{
		host: host, port: port, user: user, password: password, from: fromAddress,
		tlsConfig: &tls.Config{MinVersion: tls.VersionTLS12, ServerName: host},
	}, nil
}

func (m *SMTPMailer) SendVerificationCode(ctx context.Context, recipient, code string) error {
	to, err := mail.ParseAddress(strings.TrimSpace(recipient))
	if err != nil {
		return errors.New("verification email recipient is invalid")
	}
	if len(code) != 6 {
		return errors.New("verification code must contain six digits")
	}
	for _, digit := range code {
		if digit < '0' || digit > '9' {
			return errors.New("verification code must contain six digits")
		}
	}

	dialer := net.Dialer{Timeout: 10 * time.Second}
	connection, err := dialer.DialContext(ctx, "tcp", net.JoinHostPort(m.host, fmt.Sprint(m.port)))
	if err != nil {
		return fmt.Errorf("connect to SMTP server: %w", err)
	}
	defer connection.Close()
	deadline := time.Now().Add(15 * time.Second)
	if contextDeadline, ok := ctx.Deadline(); ok && contextDeadline.Before(deadline) {
		deadline = contextDeadline
	}
	if err := connection.SetDeadline(deadline); err != nil {
		return fmt.Errorf("set SMTP deadline: %w", err)
	}
	tlsConnection := tls.Client(connection, m.tlsConfig.Clone())
	if err := tlsConnection.HandshakeContext(ctx); err != nil {
		return fmt.Errorf("start implicit SMTP TLS: %w", err)
	}

	client, err := smtp.NewClient(tlsConnection, m.host)
	if err != nil {
		return fmt.Errorf("create SMTP client: %w", err)
	}
	defer client.Close()
	if err := client.Auth(smtp.PlainAuth("", m.user, m.password, m.host)); err != nil {
		return fmt.Errorf("authenticate with SMTP server: %w", err)
	}
	if err := client.Mail(m.from.Address); err != nil {
		return fmt.Errorf("set SMTP sender: %w", err)
	}
	if err := client.Rcpt(to.Address); err != nil {
		return fmt.Errorf("set SMTP recipient: %w", err)
	}
	writer, err := client.Data()
	if err != nil {
		return fmt.Errorf("start SMTP message: %w", err)
	}
	if _, err := io.WriteString(writer, verificationMessage(m.from, to, code)); err != nil {
		writer.Close()
		return fmt.Errorf("write SMTP message: %w", err)
	}
	if err := writer.Close(); err != nil {
		return fmt.Errorf("finish SMTP message: %w", err)
	}
	if err := client.Quit(); err != nil {
		return fmt.Errorf("finish SMTP session: %w", err)
	}
	return nil
}

func verificationMessage(from, to *mail.Address, code string) string {
	return strings.Join([]string{
		"From: " + from.String(),
		"To: " + to.String(),
		"Subject: " + mime.QEncoding.Encode("UTF-8", "行摄登录验证码"),
		"MIME-Version: 1.0",
		"Content-Type: text/plain; charset=UTF-8",
		"Content-Transfer-Encoding: 8bit",
		"",
		"您的行摄登录验证码是：" + code,
		"验证码 10 分钟内有效，请勿转发给他人。",
		"如非本人操作，请忽略此邮件。",
		"",
	}, "\r\n")
}
