# 行摄 Android MVP

行摄是一款本地优先的摄影出行应用。项目由 Flutter Android 客户端、Go API、PostgreSQL 和 Redis 组成；行程轨迹和原始照片默认只保存在手机中。

## 项目目录

- `apps/mobile`：Android 客户端
- `services/api`：API 服务和数据库迁移
- `docs`：产品、架构、接口和运维文档
- `docker-compose.yml`：PostgreSQL、Redis、API 本地服务

下面的命令均在 Windows PowerShell 中执行。

## 1. 准备本地配置

进入项目根目录，复制配置模板：

```powershell
Copy-Item .env.example .env
notepad .env
```

将 `.env` 中的 `JWT_SECRET` 改成一段至少 32 个字符、仅供本机使用的随机字符串。不要提交 `.env`，也不要把真实密码、Token 或地图 Key 写进仓库。

## 2. 启动数据库、Redis 和 API

```powershell
docker compose config
docker compose up -d --build
docker compose ps
```

`postgres`、`redis`、`api` 三个服务都应显示为 `healthy`。它们默认使用以下本机端口：

| 服务 | 地址 |
| --- | --- |
| PostgreSQL | `127.0.0.1:5432` |
| Redis | `127.0.0.1:6379` |
| API | `http://127.0.0.1:8080` |

验证服务：

```powershell
docker compose exec postgres pg_isready -U xingshe -d xingshe
docker compose exec redis redis-cli ping
curl.exe --fail http://127.0.0.1:8080/healthz
```

API 成功时会返回：

```json
{"code":"OK","message":"success","data":{"status":"ok"}}
```

## 3. 初始化数据库

首次启动以及仓库新增迁移后，都要执行：

```powershell
Set-Location services/api
$env:DATABASE_URL='postgres://xingshe:change-me-for-local-development@127.0.0.1:5432/xingshe?sslmode=disable'
go run ./cmd/migrate up
Set-Location ../..
```

上面的账号和密码对应 `.env.example`。如果修改了 `POSTGRES_DB`、`POSTGRES_USER` 或 `POSTGRES_PASSWORD`，请同步修改 `DATABASE_URL`。`down` 会回滚最近一次迁移，普通启动不要执行。

## 4. 启动 Android 客户端

先在 Android Studio 中启动模拟器，或连接已开启 USB 调试的 Android 手机。然后执行：

```powershell
Set-Location apps/mobile
flutter pub get
flutter devices
flutter run -d emulator-5554 --dart-define=MOBILE_API_BASE_URL=http://10.0.2.2:8080/api/v1
```

如果 `flutter devices` 显示的设备编号不是 `emulator-5554`，请替换命令中的编号。真机不能使用 `10.0.2.2`，应改为开发电脑的局域网 IP，例如 `http://192.168.1.10:8080/api/v1`。

## 5. 停止项目

Flutter 运行窗口按 `q` 停止客户端。回到项目根目录停止后端：

```powershell
Set-Location ../..
docker compose down
```

数据库和 Redis 数据会保留在 Docker Volume 中，下次启动仍然存在。`docker compose down -v` 会永久删除本地数据库和 Redis 数据，确认不再需要后才能执行。

## 当前限制

- 高德地图目前是可编译的占位适配器，尚未接入真实 SDK 和 Android Key。
- 开发环境 Mailer 不会真正发送验证码，因此真实邮箱登录仍需 SMTP 服务。
- 后台定位、拍照、相册和系统分享尚未完成真机验收。

## 常见问题

- 服务不是 `healthy`：运行 `docker compose logs api postgres redis` 查看错误，优先检查 `.env` 中的 `JWT_SECRET`。
- 数据库迁移连接失败：确认 PostgreSQL 已健康，并检查 `DATABASE_URL` 是否和 `.env` 一致。
- 模拟器无法访问 API：模拟器必须使用 `10.0.2.2`，不能使用 `127.0.0.1`。
- 真机无法访问 API：使用电脑局域网 IP，并确认手机与电脑在同一网络、防火墙允许访问 8080 端口。

更完整的开发与排错说明见 [docs/operations/local-development.md](docs/operations/local-development.md)。
