# 本地开发与启动

本文描述当前可运行栈：Flutter Android 客户端、Go API、PostgreSQL、Redis、数据库迁移和自动化检查。

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

`.env` 已被 Git 忽略。启动 API 前必须替换至少 32 字符的 `JWT_SECRET`，并让 `DATABASE_URL` 中的用户名、密码、端口和数据库名与 `POSTGRES_*` 保持一致。`DATABASE_URL`、`REDIS_ADDR` 和 `MIGRATIONS_URL` 供直接运行 Go 命令使用；Compose 会为容器生成对应连接配置。

真实邮件使用 `SMTP_HOST`、`SMTP_PORT`、`SMTP_USER`、`SMTP_PASSWORD` 和 `SMTP_FROM`，网易邮箱配置为 `smtp.163.com:465` 并使用隐式 TLS。开发环境可将 SMTP 变量全部留空以使用不输出验证码或邮箱的占位 Mailer，生产环境必须完整配置。`PRIVACY_CONTACT_EMAIL` 是隐私联系和外部账号删除申请的公开地址。启用地图前必须填写 `AMAP_ANDROID_KEY`。真实 Key、密码、Token、Keystore、轨迹和照片不得提交。

`JWT_ACCESS_TTL` 和 `JWT_REFRESH_TTL` 使用 Go duration 格式，默认分别为 `2h` 和 `720h`。

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

在仓库根目录通过 API 容器执行数据库迁移：

```powershell
docker compose exec api xingshe-migrate up
docker compose exec api xingshe-migrate down
```

迁移命令直接读取容器内的 `DATABASE_URL` 和镜像中的 SQL 文件。`down` 每次只回滚一个版本；正常开发使用 `up`，不要使用自动建表代替迁移。

## 4. 单独运行 API

先通过 Compose 启动依赖，再运行 Go 服务：

```powershell
docker compose up -d postgres redis
Set-Location services/api
$envFile = Resolve-Path '..\..\.env'
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
        $name = $Matches[1]
        $value = $Matches[2].Trim().Trim('"').Trim("'")
        [Environment]::SetEnvironmentVariable($name, $value, 'Process')
    }
}
go run ./cmd/migrate up
go test ./...
go vet ./...
go run ./cmd/api
```

Go 不会自动读取 `.env`，上面的 PowerShell 代码只把配置注入当前进程且不打印值。API 会读取 `APP_ENV`、数据库、Redis、JWT 和 SMTP 环境变量，校验 API/SMTP 端口，并在数据库、Redis、JWT 或部分 SMTP 配置不可用时拒绝启动。配置 SMTP 后验证码通过 465 隐式 TLS 发出；`APP_ENV=production` 禁止使用占位 Mailer。

需要回滚最近一次迁移时，在同一终端执行 `go run ./cmd/migrate down`。该命令每次只回滚一个版本，执行前先备份需要保留的数据。

## 5. 启动 Flutter Android

仓库已创建 AVD `xingshe_api_36`。启动模拟器和应用：

```powershell
Set-Location apps/mobile
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
flutter emulators --launch xingshe_api_36
flutter devices
$env:MOBILE_API_BASE_URL='http://10.0.2.2:8080/api/v1'
$amapConfigLine = Get-Content ../../.env | Where-Object { $_ -like 'AMAP_ANDROID_KEY=*' } | Select-Object -Last 1
if (-not $amapConfigLine) { throw 'AMAP_ANDROID_KEY is missing' }
$env:AMAP_ANDROID_KEY = $amapConfigLine.Substring($amapConfigLine.IndexOf('=') + 1).Trim().Trim('"').Trim("'")
$privacyConfigLine = Get-Content ../../.env | Where-Object { $_ -like 'PRIVACY_CONTACT_EMAIL=*' } | Select-Object -Last 1
if (-not $privacyConfigLine) { throw 'PRIVACY_CONTACT_EMAIL is missing' }
$env:PRIVACY_CONTACT_EMAIL = $privacyConfigLine.Substring($privacyConfigLine.IndexOf('=') + 1).Trim().Trim('"').Trim("'")
flutter build apk --debug --no-pub --dart-define=AMAP_ANDROID_KEY=$env:AMAP_ANDROID_KEY --dart-define=PRIVACY_CONTACT_EMAIL=$env:PRIVACY_CONTACT_EMAIL
flutter run -d emulator-5554 --dart-define=MOBILE_API_BASE_URL=$env:MOBILE_API_BASE_URL --dart-define=AMAP_ANDROID_KEY=$env:AMAP_ANDROID_KEY --dart-define=PRIVACY_CONTACT_EMAIL=$env:PRIVACY_CONTACT_EMAIL
```

`MOBILE_API_BASE_URL`、`AMAP_ANDROID_KEY` 和 `PRIVACY_CONTACT_EMAIL` 是编译期配置。构建进程同时从环境变量读取 `AMAP_ANDROID_KEY` 并注入 Android Manifest，Flutter 侧的地图参数用于缺失配置门禁，隐私联系参数用于公开联系和外部删除说明。真机运行时将 API 地址改为开发机局域网地址，并从被忽略的 `.env` 读取真实配置；不要在终端、日志或脚本中输出其值。未配置 Key 时地图页显示明确开发提示；配置后仍须先保存用户的地图隐私同意，再创建高德平台视图。

真机运行：

1. 在手机开发者选项中启用 USB 调试。
2. 连接手机，执行 `adb devices` 并在手机上授权。
3. 执行 `flutter run -d <device-id>`。
4. 在真机逐项验证地图、后台定位、相机、相册和系统分享；模拟器结果不能替代真机验收。

## 6. 停止与清理

停止 Flutter 运行可在终端按 `q`，或执行：

```powershell
adb shell am force-stop com.xingshe.app
docker compose down
```

`docker compose down` 保留数据库和 Redis 卷。仅在确认可以删除全部本地数据后执行 `docker compose down -v`。

数据生命周期：PostgreSQL Volume 保存账号、机位和收藏等服务端业务数据；Redis 只保存带 TTL 的临时状态。手机 Drift 数据库保存本地行程、精确轨迹和照片关联，Android 自动云备份已禁用。拍摄照片写入系统相册 `Pictures/XingShe`，导入照片只保存持久化 `content://` URI；分享 PNG 只写入应用缓存。卸载应用不会删除系统相册原图，删除行程也默认只删除关联记录。

## 7. 常见问题

- `JAVA_HOME is not set`：指向 Android Studio 的 `jbr`，重新打开终端后运行 `flutter doctor -v`。
- Gradle 或 Flutter 下载超时：使用上文 Flutter 镜像；Gradle 首次构建会下载 NDK 和 CMake。
- Go 模块下载超时：设置 `GOPROXY` 和 `GOSUMDB` 后重新执行。
- Docker Hub 超时：为 Docker Desktop 配置可信镜像加速，或先从可用镜像源拉取后重标记为 Compose 中的官方镜像名。
- 端口占用：在 `.env` 修改 `API_PORT`、`POSTGRES_PORT` 或 `REDIS_PORT`。
- 模拟器显示 `offline`：等待 `adb shell getprop sys.boot_completed` 返回 `1`；必要时重启 ADB。
- 真机无法访问 API：不要使用 `127.0.0.1` 或 `10.0.2.2`，改用开发机局域网 IP 并检查防火墙。
- 修改数据库密码后 API 无法连接：环境变量不会修改已存在 Volume 内的 PostgreSQL 密码；恢复原密码，或备份后重建 Volume。
- sqlite3 测试下载超时：项目已通过 `pubspec.yaml` 配置使用系统 SQLite，无需下载测试 DLL。
