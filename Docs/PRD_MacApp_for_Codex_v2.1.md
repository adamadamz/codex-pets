# CodexPets macOS App 产品需求与发布规格 v2.1

> 状态：Mac App Store 提交候选基线
> 更新日期：2026-08-03
> 取代：v2.0（动态宠物功能基线继续有效）

## 1. 产品目标

把标准动态宠物包变成轻量、离线的 macOS 桌面伙伴。宠物在桌面边缘待机、奔跑、
挥手、跳跃并朝光标方向观察；用户可调整大小、透明度、跟随、点击穿透和开机启动。

第一公开商店版本免费、无账号、无广告、无内购、无网络、无遥测。

## 2. 宠物包协议

```text
pet-package/
├─ pet.json
└─ spritesheet.webp
```

- 单格固定为 `192×208`，8 列。
- v1 图集为 `1536×1872`、9 行标准动作。
- v2 图集为 `1536×2288`、11 行，额外提供 16 向注视。
- 新包声明 `spriteVersionNumber: 2`；缺失字段按 v1 兼容。
- 导入前必须解码清单、限制相对路径、拒绝符号链接逃逸并验证精确尺寸。

## 3. 核心体验

1. 首次启动没有宠物时打开选择器。
2. 用户查看名称、协议版本和待机预览后确认。
3. 也可选择包含 `pet.json` 和 `spritesheet.webp` 的目录进行导入。
4. 宠物首次出现播放挥手；待机、奔跑、跳跃与 16 向注视按状态切换。
5. 双击隐藏；菜单栏和全局快捷键可以恢复显示或关闭点击穿透。
6. 所有资源和设置只保存在本机。

## 4. 两种分发渠道

### 4.1 Mac App Store（正式渠道）

- 使用 `AppStore` 构建配置并开启 App Sandbox。
- 不静默读取 `~/.codex/pets/`；用户必须在 `NSOpenPanel` 中明确选择一个宠物目录。
- 选择得到的只读 security-scoped URL 仅用于校验和复制，使用后立即释放。
- 安装后的包复制到 App 容器的 Application Support，后续不再依赖外部目录。
- 由 Apple 签名、审核和分发，用户正常从商店安装时不出现未公证 Gatekeeper 警告。

### 4.2 GitHub Preview（开发者渠道）

- `Release` 构建保持非沙盒，可自动发现 `~/.codex/pets/`。
- 在 Developer ID 与公证完成前仍是 ad-hoc 签名 Preview，首次打开会被 Gatekeeper 提醒。
- 官网必须明确标注 Preview 状态，不得暗示经过 Apple 验证。

## 5. 沙盒、隐私与合规

- 沙盒权限仅包含 `com.apple.security.files.user-selected.read-only`。
- 不申请网络、相机、麦克风、照片、通讯录、位置、辅助功能或自动化权限。
- Privacy Manifest 声明不追踪、不收集数据。
- `CACurrentMediaTime()` 只用于 App 内动画与交互的经过时间计算，Required Reason 为 `35F9.1`。
- `ITSAppUsesNonExemptEncryption = NO`；产品不实现加密功能。
- App Store 隐私标签选择 **Data Not Collected**。任何未来联网、统计或第三方 SDK 都必须重新评审。

## 6. 动画与性能边界

- 全 App 只有 `PetPhysics` 可以创建 `Timer`。
- 窗口物理、点击反馈与图集帧推进共用同一时钟。
- 开启“减弱动态效果”时停止持续序列帧，只显示当前动作首帧。
- 目标：空闲 CPU `<1%`、跟随 CPU `<5%`、内存 `<120 MB`，以真机实测为准。

## 7. App Store 商品页草案

- 分类：Utilities。
- 价格：Free。
- 支持系统：macOS 14+，Apple Silicon 与 Intel。
- 支持 URL：`https://adamadamz.github.io/codex-pets/`。
- 隐私 URL：`https://adamadamz.github.io/codex-pets/privacy/`。
- 审核备注需说明：App 是菜单栏常驻桌面挂件；首次启动需导入本地宠物包；无登录、无联网。
- 商店名称仍受名称门禁约束。2026-08-03 复查 US/CN Apple Search API 时，`FuzzOrbit`、
  `Fuzz Orbit` 均无精确同名，`fuzzorbit.com` / `.app` 的公共 RDAP 查询仍为 404；但这不代表
  App Store Connect 可占位或商标清除，`FuzzOrbit` 仍只是 Conditional Go 工作名。

## 8. 发布门禁

提交前必须全部满足：

1. App Store Connect 名称可创建，并完成必要的商标/近似复核。
2. Apple Developer Program 成员资格有效，协议、税务与银行信息状态允许提交免费 App。
3. Bundle ID、Apple Distribution 证书和 Mac App Store provisioning 可用。
4. `AppStore` 配置的测试、Universal build、沙盒签名归档与 `Validate App` 通过。
5. 在沙盒构建上完成导入、动画、快捷键、点击穿透、开机启动和多显示器运行时验收。
6. AppIcon、截图、描述、隐私标签、年龄分级、版权和审核备注齐全。

## 9. 当前验收状态

- 已完成：独立 App Store 配置、最小沙盒权限、security-scoped 导入、Privacy Manifest、
  Utilities 分类、出口合规声明和全尺寸 AppIcon 候选。
- 已验证：24 个单元测试、AppStore Universal 无签名构建、Apple Development 沙盒签名
  构建与 Universal `.xcarchive`；归档签名内只包含 App Sandbox 和用户选择目录只读权限。
- 待验证：Mac Installer Distribution 导出、App Store Connect 上传与 Organizer Validate。
- 已确认的本机缺项：`Mac Installer Distribution` 证书，以及
  `com.decodegroup.codexpets` 的 Mac App Store provisioning profile。
- 账号侧已有 Team `66HPXF4XN5` 的有效 iOS Store profiles（到期 2027-06-11），但这不能
  代替 App Store Connect 的协议/权限确认，也不能生成缺失的 Mac 发行凭据。
- 外部阻塞：名称占位/法律复核、Apple Distribution 证书、Mac App Store provisioning、
  App Store Connect 权限与商店法律信息。
- 未经用户明确要求，不启动 App 做运行时交互或截图采集。
