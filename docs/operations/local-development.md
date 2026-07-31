# 本地开发与启动

本文描述当前可运行栈：Flutter Android 启动页、Go API、PostgreSQL 和 Redis。后续任务增加迁移及业务命令时必须同步更新本文。

## 1. 已验证工具链

| 工具 | 已验证版本 | 安装说明 |
| --- | --- | --- |
| Flutter | stable 3.44.8 / Dart 3.12.2 | 解压到 `C:\src\flutter`，将 `C:\src\flutter\bin` 加入 `PATH` |
| Android Studio | 2026.1.3.7 | 安装 Android SDK 36、Build Tools 36.0.0、Platform Tools、Emulator 和 Android 36 Google APIs x86_64 镜像 |
| JDK | Android Studio JBR 25.0.2 | 设置 `JAVA_HOME=C:\Program Files\Android\Android Studio\jbr` |
| Go | 1.26.5 | 使用官方 Windows MSI，确认 `go version` |
| Docker Desktop | 29.5.3 | 启用 WSL 2 后端，确认 Linux containers 正在运行 |

设置 Android 环境变量：

```powershell
$env:ANDROID_HOME="$env:LOCALAPPDATA\Android\Sdk"
$env:JAVA_HOME='C:\Program Files\Android\Android Studio\jbr'
$env:PATH="C:\src\flutter\bin;$env:JAVA_HOME\bin;$env:ANDROID_HOME\platform-tools;$env:PATH"
flutter config --android-sdk $env:ANDROID_HOME
flutter config --jdk-dir $env:JAVA_HOME
flutter doctor --android-licenses
flutter doctor -v
```

Windows 桌面开发的 Visual Studio 警告不影响本项目的 Android MVP。网络检查无法访问 Google 时，可设置：

```powershell
$env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'
$env:GOPROXY='https://goproxy.cn,direct'
$env:GOSUMDB='sum.golang.google.cn'
```

## 2. 本地配置

在仓库根目录执行：

```powershell
Copy-Item .env.example .env
```

`.env` 已被 Git 忽略。启动 API 前必须替换至少 32 字符的 `JWT_SECRET`；开发环境使用不输出验证码或邮箱的 Mock Mailer，生产邮件实现接入前 SMTP 变量保持为空；启用地图前必须填写 `AMAP_ANDROID_KEY`。真实 Key、密码、Token、Keystore、轨迹和照片不得提交。

`MOBILE_API_BASE_URL` 默认使用 Android 模拟器访问宿主机的地址 `10.0.2.2`。真机应改为开发机的局域网地址，并确保防火墙仅允许可信网络。

## 3. 启动完整本地栈

先验证配置，再启动三个固定服务：

```powershell
docker compose config
docker compose up -d --build
docker compose ps
```

验证 PostgreSQL、Redis 和 API：

```powershell
docker compose exec postgres pg_isready -U xingshe -d xingshe
docker compose exec redis redis-cli ping
curl.exe --fail http://127.0.0.1:8080/healthz
```

健康响应应为：

```json
{"code":"OK","message":"success","data":{"status":"ok"}}
```

从 `services/api` 执行数据库迁移：

```powershell
$env:DATABASE_URL='postgres://xingshe:change-me-for-local-development@127.0.0.1:5432/xingshe?sslmode=disable'
go run ./cmd/migrate up
go run ./cmd/migrate down
```

`down` 每次只回滚一个版本。正常开发使用 `up`；不要使用自动建表代替迁移。

## 4. 单独运行 API

先通过 Compose 启动依赖，再运行 Go 服务：

```powershell
docker compose up -d postgres redis
Set-Location services/api
go test ./...
go vet ./...
$env:API_PORT='8080'
go run ./cmd/api
```

API 会读取 `APP_ENV`、数据库、Redis、JWT 和 SMTP 环境变量，校验 API/SMTP 端口，并在数据库、Redis 或 JWT 配置不可用时拒绝启动。生产 SMTP 发送器尚未接入，因此 `APP_ENV=production` 会明确报错。

## 5. 启动 Flutter Android

仓库已创建 AVD `xingshe_api_36`。启动模拟器和应用：

```powershell
Set-Location apps/mobile
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
flutter emulators --launch xingshe_api_36
flutter devices
flutter run -d emulator-5554
```

真机运行：

1. 在手机开发者选项中启用 USB 调试。
2. 连接手机，执行 `adb devices` 并在手机上授权。
3. 执行 `flutter run -d <device-id>`。
4. 后续接入地图、后台定位、相机和分享后，必须按任务要求在真机逐项验收。

## 6. 停止与清理

停止 Flutter 运行可在终端按 `q`，或执行：

```powershell
adb shell am force-stop com.xingshe.app
docker compose down
```

`docker compose down` 保留数据库和 Redis 卷。仅在确认可以删除全部本地数据后执行 `docker compose down -v`。

## 7. 常见问题

- `JAVA_HOME is not set`：指向 Android Studio 的 `jbr`，重新打开终端后运行 `flutter doctor -v`。
- Gradle 或 Flutter 下载超时：使用上文 Flutter 镜像；Gradle 首次构建会下载 NDK 和 CMake。
- Go 模块下载超时：设置 `GOPROXY` 和 `GOSUMDB` 后重新执行。
- Docker Hub 超时：为 Docker Desktop 配置可信镜像加速，或先从可用镜像源拉取后重标记为 Compose 中的官方镜像名。
- 端口占用：在 `.env` 修改 `API_PORT`、`POSTGRES_PORT` 或 `REDIS_PORT`。
- 模拟器显示 `offline`：等待 `adb shell getprop sys.boot_completed` 返回 `1`；必要时重启 ADB。
- 真机无法访问 API：不要使用 `127.0.0.1` 或 `10.0.2.2`，改用开发机局域网 IP 并检查防火墙。
- sqlite3 测试下载超时：项目已通过 `pubspec.yaml` 配置使用系统 SQLite，无需下载测试 DLL。
