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
docker compose exec api xingshe-migrate up
```

迁移程序直接使用容器配置，无需手工填写数据库连接字符串。`down` 会回滚最近一次迁移，普通启动不要执行。

## 数据存在哪里

| 数据 | 存储位置 |
| --- | --- |
| 用户、机位、收藏、Token 哈希 | PostgreSQL Docker Volume |
| 限流、登录失败计数等临时数据 | Redis（带过期时间） |
| 登录 Token、设备 ID | Android 安全存储 |
| 行程、精确轨迹、照片关联 | 手机 Drift/SQLite |
| 新拍原图 | 系统相册 `Pictures/XingShe`（H04 实现） |
| 导入原图 | 保留原文件，应用只保存 `content://` URI（H05 实现） |
| 缩略图、分享图 | 应用缓存，可自动清理 |

`docker compose down` 会保留 PostgreSQL 和 Redis Volume；`docker compose down -v` 才会永久删除它们。卸载应用会删除手机内的行程、轨迹和应用缓存，但系统相册原图仍保留。删除行程默认只删除数据库关联；删除系统原图必须单独确认。Android 自动云备份已禁用，因此当前本地行程应按“仅此设备一份”看待，导出与恢复功能将在后续迭代补充。

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

- Android 地图使用高德 SDK；首次进入前必须明确同意地图隐私说明，Key 仅通过本地构建环境注入。
- 配置完整 SMTP 环境变量后，API 通过 465 端口隐式 TLS 发送真实验证码；未配置时开发环境使用不输出邮箱或验证码的占位 Mailer。
- 行程、轨迹、统计、照片关联和分享图均为本地优先；精确轨迹与原始照片不上传服务器。
- Room 后台缓冲、拍照、相册导入和安全 `FileProvider` 分享已实现，但当前没有 Android 真机，相关硬件流程尚未完成真机验收。

## 常见问题

- 服务不是 `healthy`：运行 `docker compose logs api postgres redis` 查看错误，优先检查 `.env` 中的 `JWT_SECRET`。
- 数据库迁移连接失败：确认 PostgreSQL 与 API 均健康，并用 `docker compose config` 检查 `.env` 是否已生效。
- 修改 `.env` 数据库密码后连接失败：旧 PostgreSQL Volume 不会自动改密码；恢复创建 Volume 时的密码，或确认不需要旧数据后执行 `docker compose down -v` 重新初始化。
- 模拟器无法访问 API：模拟器必须使用 `10.0.2.2`，不能使用 `127.0.0.1`。
- 真机无法访问 API：使用电脑局域网 IP，并确认手机与电脑在同一网络、防火墙允许访问 8080 端口。

## 相关文档

- [本地开发与排错](docs/operations/local-development.md)
- [系统架构](docs/architecture.md)
- [OpenAPI 接口](docs/api/openapi.yaml)
- [隐私、权限与删除](docs/privacy.md)
- [部署、备份与恢复建议](docs/operations/deployment.md)
