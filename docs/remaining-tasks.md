# 行摄 Android MVP 未完成任务

更新日期：2026-08-05  
当前分支：`feature/mvp-auto-development`  
当前已推送基线：`f2e6933 feat(privacy): add external account deletion guidance`

## 1. 当前结论

A01–L03 以及 M01 已完成。网易 SMTP 465 隐式 TLS、高德 Android SDK、地图隐私同意、账号删除 API、客户端账号删除流程和外部删除申请说明均已完成。

当前停止于 M02。开发机没有连接 Android 真机，因此不能完成真机验收，也不能用模拟器、Windows 或 Web 运行结果代替。

## 2. 已完成的最终前置

| 项目 | 状态 | 说明 |
| --- | --- | --- |
| J04 自动化分享隐私检查 | 已完成 | 分享图不包含 Token、邮箱或精确地址；真机系统分享仍待 M02 验证 |
| 账号删除 API | 已完成 | 删除用户、验证码、刷新 Token 和收藏；旧访问 Token 立即失效 |
| 客户端账号删除 | 已完成 | 包含风险说明、二次确认、处理中、成功、失败、取消和退出登录状态 |
| 本地数据边界 | 已完成 | 本地行程默认保留；可选清理 Drift 行程和 Room 待同步点；不删除系统相册原图 |
| 外部删除申请 | 已完成 | 未登录状态可查看，联系方式通过 `PRIVACY_CONTACT_EMAIL` 编译期注入 |
| M01 全量自动化门禁 | 已完成 | Flutter 68 项测试、Go 测试、数据库/Redis 集成流、Compose、Docker 和 Debug APK 均通过 |

M01 未发现需要修复的质量问题，因此没有创建空的 `chore(quality)` 提交。

## 3. M02 Android 真机验收

### 状态

阻塞。`adb devices -l` 未发现 Android 设备；Flutter 仅发现 Windows、Chrome 和 Edge。

### 所需条件

1. Android 真机一台。
2. 开启开发者选项和 USB 调试。
3. 在手机上确认当前开发机的调试授权。
4. `adb devices -l` 中设备状态为 `device`，不是 `unauthorized` 或 `offline`。
5. 真机能访问开发机 API，并通过被 Git 忽略的 `.env` 注入本地配置。

### 验收清单

- [ ] 首次进入地图前显示 SDK 和位置数据说明。
- [ ] 不同意时不初始化高德 SDK，同意后地图可正常显示。
- [ ] 网易邮箱验证码发送、登录、会话恢复和登出通过。
- [ ] 机位列表、搜索、Marker、详情、收藏和附近推荐通过。
- [ ] 开始行摄后才启动前台定位服务和常驻通知。
- [ ] 锁屏和切入后台时持续记录，暂停时不新增轨迹，继续后恢复。
- [ ] 应用重启后可恢复进行中或暂停的行程。
- [ ] 拍照写入 `Pictures/XingShe`，相册多选及取消流程正常。
- [ ] 结束行摄后定位服务和通知消失，行程被封存且不再写入轨迹。
- [ ] 历史列表、详情轨迹、照片墙、行程删除和系统原图边界正确。
- [ ] 分享 PNG 生成并进入 Android 系统分享面板；取消分享不报错。
- [ ] 分享图不包含 Token、邮箱或精确隐私地址，完成 J04 真机部分。
- [ ] 应用内账号删除的保留本地行程和清理本地行程两种路径通过。
- [ ] 账号删除后 Token 失效并返回未登录状态，系统相册原图仍保留。

### 产出

记录设备型号、Android 版本、应用构建、测试时间和每个验收项结果，但不记录验证码、Token、真实轨迹、邮箱、照片或其他用户数据。

规定提交：

```text
test(android): document MVP device acceptance results
```

## 4. M03 安全与隐私审查

前置：M02 通过。

- [ ] 检查 `.gitignore`、当前 Git 跟踪文件和历史中的密钥、密码、Token 和签名文件。
- [ ] 复核 Token 安全存储、刷新、登出和账号删除后的失效语义。
- [ ] 复核 API 鉴权、参数校验、删除级联和旧访问 Token 失效。
- [ ] 复核客户端和服务端日志脱敏，确认不输出 Authorization、验证码和精确坐标。
- [ ] 复核定位、相机、照片和地图 SDK 隐私同意的按需申请。
- [ ] 复核行程、轨迹、照片关联、系统原图和分享缓存的删除边界。
- [ ] 确认轨迹和原始照片没有上传服务端。
- [ ] 生成安全与隐私审查文档。

规定提交：

```text
docs(security): add MVP privacy and security review
```

## 5. M04 MVP 交付清单

前置：M03 通过。

- [ ] 汇总 Flutter、Go、Docker Compose 和数据库迁移启动步骤。
- [ ] 列出 `.env.example` 的配置项和本地注入方式，不包含真实值。
- [ ] 记录 Android Debug 构建方式和 Release 签名尚未配置的限制。
- [ ] 汇总自动化测试、M02 真机验收和 M03 审查结果。
- [ ] 列出已知限制、生产外部依赖和后续迭代建议。
- [ ] 确保新成员可仅依赖仓库文档完成本地启动。

规定提交：

```text
docs(delivery): add MVP handoff checklist
```

## 6. M05 最终完成报告

前置：M04 通过。

最终报告必须包含：

1. 项目完成状态和已完成功能。
2. 未实现的非 MVP 功能。
3. 技术架构和数据边界。
4. Flutter、API、Docker 和迁移的本地启动方式。
5. Android Debug 构建方式。
6. 自动化测试、真机验收和安全审查结果。
7. Git 分支、提交清单和工作区状态。
8. 已知限制、外部配置和上线前检查清单。
9. 下一阶段建议。

规定提交：

```text
docs(delivery): publish final MVP completion report
```

如 M05 仅输出报告且仓库无文件变更，不创建空提交。

## 7. 明确不在当前范围

以下项目不是当前 M02–M05 的开发任务，只能在未来生产发布前由用户或运维人员完成：

- 生产服务器、域名、HTTPS、PostgreSQL 和 Redis 的正式部署。
- Android 正式 Release Keystore 和发布签名。
- 应用商店账号、提交审核和上架。
- 正式隐私政策 URL、应用商店数据安全声明和法务审核。
- 任何真实用户数据、轨迹或照片的导入与上传。

## 8. 恢复执行方式

连接真机后，先执行：

```powershell
adb devices -l
flutter devices
```

确认 Android 真机可用后，从 M02 的第一个验收项继续。不跳过 M02，不提前开始 M03–M05。
