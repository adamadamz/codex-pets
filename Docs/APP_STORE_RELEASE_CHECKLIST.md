# Mac App Store 发布清单

> 更新日期：2026-08-03
> 当前结论：工程准备中；尚未提交 App Store Connect。

## 工程检查

- [x] `AppStore` Release 配置。
- [x] App Sandbox 开启。
- [x] 仅申请用户选择目录的只读权限。
- [x] 外部目录使用 security-scoped access，复制完成后释放。
- [x] App 容器内持久化。
- [x] Privacy Manifest：不追踪、不收集数据；声明 System Boot Time 原因 `35F9.1`。
- [x] `ITSAppUsesNonExemptEncryption = NO`。
- [x] Utilities 分类。
- [x] 16px–1024px AppIcon 候选。
- [x] Apple Development 沙盒签名构建和 Universal `.xcarchive`，签名及 entitlement 校验通过。
- [ ] Apple Distribution 沙盒签名归档与 App Store Connect 导出。
- [ ] Organizer `Validate App` 通过。

## Apple 账号检查

- [x] 本机存在 Team `66HPXF4XN5` 的有效 iOS Store profiles（到期 2027-06-11），说明发行团队凭据处于活动状态；仍需在 App Store Connect 直接确认协议状态。
- [ ] App Store Connect 中可创建 Mac App，协议状态无阻塞。
- [ ] 正式名称完成占位和必要的法律复核。
- [ ] 显式 Bundle ID 已注册。
- [ ] Mac App Distribution / Mac Installer Distribution 证书可用。
- [ ] `com.decodegroup.codexpets` 的 Mac App Store provisioning profile 可用。
- [ ] 上传账号具有 App Manager 或 Admin 权限，或配置 App Store Connect API Key。

## 商品页检查

- [ ] 名称、副标题、描述、关键词和本地化。
- [ ] 支持 URL、隐私 URL。
- [ ] 年龄分级、版权、App Review 联系信息。
- [ ] App 隐私选择“Data Not Collected”。
- [ ] macOS 截图来自最终沙盒签名构建，不伪造未验证功能。
- [ ] 审核备注说明菜单栏入口、宠物包导入步骤、无登录与无联网。

## 本地验证命令

```bash
./scripts/validate-app-store-build.sh
```

签名条件具备后，使用 Xcode Organizer 对 `CodexPets` scheme 执行 Archive。该 scheme 的
Archive 动作已绑定 `AppStore` 配置。先运行 `Validate App`，再由账号持有人确认上传。

命令行导出使用 `Config/ExportOptions-AppStore.plist`；该步骤需要 Apple Distribution
证书和有效的 Mac App Store provisioning profile。2026-08-03 的本地导出检查精确返回：
`No signing certificate "Mac Installer Distribution" found` 与
`No profiles for 'com.decodegroup.codexpets' were found`。
