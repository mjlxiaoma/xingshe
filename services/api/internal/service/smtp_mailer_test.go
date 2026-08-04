package service

import (
	"bufio"
	"context"
	"crypto/rand"
	"crypto/rsa"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/pem"
	"fmt"
	"math/big"
	"net"
	"strings"
	"testing"
	"time"
)

func TestSMTPMailerUsesImplicitTLS(t *testing.T) {
	serverTLS, roots := smtpTestTLS(t)
	listener, err := tls.Listen("tcp", "127.0.0.1:0", serverTLS)
	if err != nil {
		t.Fatal(err)
	}
	defer listener.Close()
	received := make(chan string, 1)
	serverError := make(chan error, 1)
	go serveSMTPTestConnection(listener, received, serverError)

	mailer, err := NewSMTPMailer("localhost", listener.Addr().(*net.TCPAddr).Port, "sender@example.com", "test-password", "行摄 <sender@example.com>")
	if err != nil {
		t.Fatal(err)
	}
	mailer.tlsConfig.RootCAs = roots
	if err := mailer.SendVerificationCode(context.Background(), "recipient@example.com", "123456"); err != nil {
		t.Fatal(err)
	}
	if err := <-serverError; err != nil {
		t.Fatal(err)
	}
	message := <-received
	if !strings.Contains(message, "Content-Type: text/plain; charset=UTF-8") || !strings.Contains(message, "123456") {
		t.Fatal("SMTP server did not receive the verification message")
	}
}

func TestSMTPMailerRejectsUnsafeInput(t *testing.T) {
	if _, err := NewSMTPMailer("smtp.example.com", 465, "sender", "password", "invalid"); err == nil {
		t.Fatal("expected invalid sender error")
	}
	mailer, err := NewSMTPMailer("smtp.example.com", 465, "sender", "password", "sender@example.com")
	if err != nil {
		t.Fatal(err)
	}
	if err := mailer.SendVerificationCode(context.Background(), "recipient@example.com\r\nBcc:other@example.com", "123456"); err == nil {
		t.Fatal("expected injected recipient error")
	}
	if err := mailer.SendVerificationCode(context.Background(), "recipient@example.com", "not-six"); err == nil {
		t.Fatal("expected invalid code error")
	}
}

func serveSMTPTestConnection(listener net.Listener, received chan<- string, result chan<- error) {
	connection, err := listener.Accept()
	if err != nil {
		result <- err
		return
	}
	defer connection.Close()
	reader := bufio.NewReader(connection)
	write := func(value string) error {
		_, err := fmt.Fprint(connection, value)
		return err
	}
	read := func(prefix string) error {
		line, err := reader.ReadString('\n')
		if err != nil {
			return err
		}
		if !strings.HasPrefix(line, prefix) {
			return fmt.Errorf("expected %s command", prefix)
		}
		return nil
	}
	if err := write("220 localhost ESMTP\r\n"); err != nil {
		result <- err
		return
	}
	steps := []struct {
		command  string
		response string
	}{
		{"EHLO", "250-localhost\r\n250 AUTH PLAIN\r\n"},
		{"AUTH PLAIN", "235 authenticated\r\n"},
		{"MAIL FROM:", "250 ok\r\n"},
		{"RCPT TO:", "250 ok\r\n"},
		{"DATA", "354 continue\r\n"},
	}
	for _, step := range steps {
		if err := read(step.command); err != nil {
			result <- err
			return
		}
		if err := write(step.response); err != nil {
			result <- err
			return
		}
	}
	var message strings.Builder
	for {
		line, err := reader.ReadString('\n')
		if err != nil {
			result <- err
			return
		}
		if line == ".\r\n" {
			break
		}
		message.WriteString(line)
	}
	if err := write("250 queued\r\n"); err != nil {
		result <- err
		return
	}
	if err := read("QUIT"); err != nil {
		result <- err
		return
	}
	if err := write("221 bye\r\n"); err != nil {
		result <- err
		return
	}
	received <- message.String()
	result <- nil
}

func smtpTestTLS(t *testing.T) (*tls.Config, *x509.CertPool) {
	t.Helper()
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	template := &x509.Certificate{
		SerialNumber: big.NewInt(1), Subject: pkix.Name{CommonName: "localhost"},
		NotBefore: time.Now().Add(-time.Minute), NotAfter: time.Now().Add(time.Hour),
		KeyUsage:    x509.KeyUsageKeyEncipherment | x509.KeyUsageDigitalSignature,
		ExtKeyUsage: []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth}, DNSNames: []string{"localhost"},
	}
	certificateDER, err := x509.CreateCertificate(rand.Reader, template, template, &key.PublicKey, key)
	if err != nil {
		t.Fatal(err)
	}
	certificatePEM := pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: certificateDER})
	keyPEM := pem.EncodeToMemory(&pem.Block{Type: "RSA PRIVATE KEY", Bytes: x509.MarshalPKCS1PrivateKey(key)})
	certificate, err := tls.X509KeyPair(certificatePEM, keyPEM)
	if err != nil {
		t.Fatal(err)
	}
	rootCertificate, err := x509.ParseCertificate(certificateDER)
	if err != nil {
		t.Fatal(err)
	}
	roots := x509.NewCertPool()
	roots.AddCert(rootCertificate)
	return &tls.Config{Certificates: []tls.Certificate{certificate}, MinVersion: tls.VersionTLS12}, roots
}
