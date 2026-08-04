# Architecture

## Status

当前 Android MVP 已实现 Flutter 客户端、Kotlin 原生桥、Go API、PostgreSQL、Redis、Drift v2、Room 定位缓冲、高德地图、照片关联和本地分享。生产部署、正式签名和 Android 真机验收不在当前完成状态内。

## System shape

```text
Flutter UI and business state
  |-- HTTPS/JSON --> Go API --> PostgreSQL
  |                         `-> Redis
  |-- platform channels --> Kotlin services and Android system APIs
  `-- Drift/SQLite -------> local trips, tracks, statistics, photo links

Kotlin foreground location service --> Room retry buffer --> Drift sync
Android MediaStore/document picker -----------------------> content:// links
RepaintBoundary --> app cache PNG --> FileProvider --> Android share sheet
```

- Flutter/Dart 负责页面、认证状态、行程状态机、Drift 数据、统计和分享卡。
- Kotlin 负责前台定位服务、Room 缓冲、相机/相册桥和安全系统分享。
- Go API 负责邮箱登录、Token 轮换、用户资料、机位和收藏；接口以 `docs/api/openapi.yaml` 为准。
- PostgreSQL 是服务端持久业务主库，Redis 只保存带 TTL 的限流和登录失败状态。
- API 不提供行程、精确轨迹或原始照片上传端点。

## Authentication

邮箱验证码经 Mailer 接口发送。开发环境未配置 SMTP 时使用不记录邮箱和验证码的占位实现；配置网易 SMTP 后通过 465 隐式 TLS 发送。验证码只以 HMAC 哈希保存并一次性消费。

访问 Token 使用短期 JWT，刷新 Token 使用随机值且服务端只保存哈希。刷新会撤销旧 Token 并签发新 Token；登出撤销对应刷新 Token。Android 客户端把 Token 和设备 ID 保存到安全存储，自动云备份已关闭。

## Trip lifecycle

行程状态为 `draft -> recording <-> paused -> completed`。同一设备最多存在一个 recording/paused 行程，非法转换由控制器拒绝。暂停时间不计入最终时长；完成行程时依次停止前台定位、导入 Room 缓冲、重算距离并封存数据。

Kotlin 服务先把 WGS-84 定位点写入 Room。Flutter 按唯一 `nativeLogId` 幂等同步到 Drift，成功后清理 Room；应用或 Flutter 引擎短暂退出时，Room 仍是重试缓冲而不是第二个业务主库。地图边界按点把 WGS-84 转为 GCJ-02。

## Media and sharing

- 新拍原图由 MediaStore 保存到 `Pictures/XingShe`；导入原图保留在用户选择的位置。
- Drift 只保存持久化 `content://` URI 和必要元数据，不复制大文件，不上传原图。
- 删除行程级联删除轨迹、统计和照片关联，不自动删除系统相册原图。
- 分享卡只使用标题、日期、统计、照片数和归一化路线形状，不读取机位地址、邮箱或 Token。
- PNG 写入应用缓存，经私有 `FileProvider` 只读授权给 Android 系统分享面板，不暴露私有文件路径。

## Privacy and failure boundaries

- 高德平台视图只能在用户保存 SDK 隐私同意后创建；不同意时不得初始化 SDK。
- 权限按使用时机申请，结束行程后必须停止前台定位服务。
- 客户端错误报告仅允许内部事件、白名单错误码和 HTTP 状态；服务端请求日志不记录 Header、Query、请求体或 panic 内容。
- PostgreSQL/Redis/API 故障不影响已封存的本地行程；Room 同步失败保留待同步点。
- 分享生成失败保留行程数据，系统分享取消不视为错误。

## Repository boundaries

```text
apps/mobile        Flutter Android client and Kotlin bridges
services/api       Go HTTP API and SQL migrations
docs/api           OpenAPI contract
docs/adr           durable architecture decisions
docs/operations    local development and deployment guidance
docker-compose.yml local PostgreSQL, Redis, and API stack
```
