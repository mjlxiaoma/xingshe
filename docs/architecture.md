# Architecture

## Status

Accepted and partially implemented. Flutter、Go API、PostgreSQL、Redis、认证、机位、收藏与 Drift v2 基础已落地；Room 定位缓冲、拍照和行程业务仍按任务清单实现。

## Data ownership

- PostgreSQL 是账号、机位、收藏和 Token 哈希的服务端业务主库。
- Redis 只保存限流、失败计数等带 TTL 的临时状态，可从业务主库和请求重新生成，不是持久业务源。
- Drift/SQLite 是单台设备上行程、精确轨迹、统计和照片关联的主库；登出或切换账号不清理这些本地行程。
- Room/SQLite 由 Kotlin 前台定位服务作为短期缓冲；Flutter 通过唯一 `nativeLogId` 幂等写入 Drift 后清理已同步记录。
- 新拍原图归系统 MediaStore `Pictures/XingShe` 所有；导入原图保持原位置，数据库只保存持久化 `content://` URI。
- 缩略图和分享图片属于可清理应用缓存。未来头像和机位封面才使用对象存储/CDN，数据库只保存 URL。

## System shape

- Flutter/Dart 负责 Android UI、业务编排和 Drift 数据。
- Kotlin 负责前台定位、通知、Room 缓冲与 Flutter 通道；结束行摄必须停止服务。
- 无状态 Go API 负责账号、机位和收藏，OpenAPI 定义移动端边界。
- 精确轨迹和原图不上云，本期不提供行程云同步 API。
- 所有坐标明确记录 WGS-84 或 GCJ-02，转换发生在清晰的边界。
- Android 自动云备份关闭，避免 Token 和精确位置进入系统云备份。

## Repository boundaries

```text
apps/mobile        Flutter Android client and Kotlin bridge
services/api       Go HTTP API
docs               Product, API, architecture and operations decisions
docker-compose.yml Local PostgreSQL, Redis and API stack
```
