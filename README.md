# CodexPets

Codex 动态宠物 → macOS 桌面伙伴。读取标准宠物图集、渲染和存储全部在本机完成，断网可用。

> 独立开源项目，与 OpenAI 无隶属或背书关系。Codex 是其各自权利人的商标。

- 官网：<https://adamadamz.github.io/codex-pets/>
- 下载：<https://github.com/adamadamz/codex-pets/releases>
- 最新产品规格：[`Docs/PRD_MacApp_for_Codex_v2.1.md`](Docs/PRD_MacApp_for_Codex_v2.1.md)
- Mac App Store 提交清单：[`Docs/APP_STORE_RELEASE_CHECKLIST.md`](Docs/APP_STORE_RELEASE_CHECKLIST.md)
- SEO、AEO 与 AI Agent 搜索策略：[`Docs/SEO_AEO_AI_SEARCH_STRATEGY.md`](Docs/SEO_AEO_AI_SEARCH_STRATEGY.md)
- Codex 提示词与蒸馏方案：[`Docs/Prompt_Pack_v1.0.md`](Docs/Prompt_Pack_v1.0.md)

## 下载 Preview

GitHub Releases 提供 macOS 14+ 的 Universal 构建，兼容 Apple Silicon 与 Intel Mac。

当前 Preview 使用 ad-hoc 签名，尚未完成 Developer ID 签名与 Apple 公证。首次打开时：

1. 把 `CodexPets.app` 移到“应用程序”，尝试打开一次；
2. 前往“系统设置 → 隐私与安全”，在安全性区域点击“仍要打开”；
3. 如果该入口没有出现，可只解除此 App 的隔离标记：

```bash
xattr -dr com.apple.quarantine /Applications/CodexPets.app
open /Applications/CodexPets.app
```

不要全局关闭 Gatekeeper。需要正式公开分发体验时，仍须完成 Developer ID 签名、公证与干净设备验收。

## Mac App Store 路线

工程现在包含独立的 `AppStore` 构建配置：开启 App Sandbox，只允许读取用户在系统选择器中
明确选中的宠物包，并声明“Data Not Collected”和所需的 Required Reason API。通过 Mac App Store
安装后由 Apple 完成签名和分发，不会出现 GitHub Preview 的 Gatekeeper 未公证警告。

当前尚不能声称已经提交：本机已通过 Apple Development 沙盒签名并生成 Universal
`.xcarchive`，但 App Store 导出明确缺少 `Mac Installer Distribution` 证书和
`com.decodegroup.codexpets` 的 Mac App Store provisioning profile；同时仍需完成商店名称、
法律信息和截图。

## 当前状态

动态宠物主链路已完成第一次静态收敛：

- XcodeGen 2.45.4 生成工程成功
- Xcode 26.6 无签名 Debug build 成功
- 只接受 Codex `pet.json + spritesheet.webp` 动态宠物包，不再把普通照片当宠物
- 兼容 v1 的 9 行动作图集，优先支持 v2 的 9 组动作 + 16 向注视
- GitHub Preview 自动发现 `~/.codex/pets/`；Mac App Store 沙盒版改为用户从系统选择器明确导入
- 旧版 `pet.png` 保留在本机作为迁移数据，但不再进入渲染主路径
- 物理跟随、惯性和阻尼已改为帧率无关计算
- 多显示器选择具备中心、相交面积和最近距离三级兜底
- 22 个定向单元测试全部通过
- 菜单入口改为“选择动态宠物…”，选择器会显示宠物版本与待机预览
- 点击穿透增加条件恢复菜单与 `⇧⌥⌘P` 紧急恢复快捷键
- v2 动态链路尚未启动做交互验收；旧版记录仅作为历史证据

本轮遵守运行边界，没有启动 App。动作切换、WebP 实际呈现、点击穿透下层命中、
真实系统级按键事件、多显示器和性能仍需单独授权后验收。

## 构建

需要 Xcode 26.x、macOS 14.0+。

```bash
brew install xcodegen        # 首次
cd CodexPets
xcodegen generate
xcodebuild \
  -project CodexPets.xcodeproj \
  -scheme CodexPets \
  -configuration Debug \
  -derivedDataPath /tmp/CodexPetsDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

运行 App 不属于默认静态验证步骤。需要交互验收时，在 Xcode 中选择自己的 Team 后运行。

## 用法

1. 启动后从发现到的 Codex 动态宠物中选择一只
2. 也可导入一个同时包含 `pet.json` 和 `spritesheet.webp` 的目录
3. 宠物出现在屏幕右下角并播放动作。拖它、点它、让它跟着鼠标
4. 所有调参在菜单栏的爪印图标里
5. `⌥⌘P` 显示 / 隐藏；`⇧⌥⌘P` 关闭点击穿透并恢复宠物

## 代码结构

```
Sources/
├─ CodexPetsApp.swift          @main，AppKit accessory app（不进 Dock）
├─ PetConfig.swift             唯一配置层 + 区间校验（Codex 只写这个文件）
├─ PetStore.swift              动态宠物发现、校验、复制与持久化
├─ ImageMatting/               v1 历史图片工具（不在 v2 宠物主路径）
├─ PetRuntime/
│  ├─ PetPanel.swift           NSPanel 悬浮窗 + PetController
│  ├─ PetPhysics.swift         全 App 唯一动画时钟（物理 + 图集帧）
│  ├─ PetSprite.swift          Codex v1/v2 协议、切片、动作与 16 向注视
│  ├─ PetMotionMath.swift      帧率无关的跟随、惯性与 dt 计算
│  ├─ PetScreenGeometry.swift  可测试的多显示器选择规则
│  └─ PetView.swift            SwiftUI 纯展示 + 鼠标事件宿主
├─ Residency/
│  ├─ TrayController.swift     菜单栏与全部调参
│  ├─ HotKey.swift             Carbon 全局快捷键（不需辅助功能授权）
│  └─ LaunchAtLogin.swift      SMAppService
└─ ImportWindow/
   └─ PetPickerViewController.swift  动态宠物选择与包导入
```

## 三条不能碰的红线

1. **只有一个动画时钟**。`PetPhysics` 的定时器是唯一的。不要在 SwiftUI 侧写
   自驱动循环——两套时钟叠加是这类 App CPU 飙升的头号原因。
2. **不联网**。宠物包解析与渲染全本地，Info.plist 里 ATS 已关。一旦加入任何网络或统计代码，
   App Store 隐私标签就必须从 "Data Not Collected" 改掉，属于审核红线。
3. **不引入第三方依赖**。MVP 只使用 AppKit、SwiftUI、Vision、CoreImage、ImageIO、
   UniformTypeIdentifiers、ServiceManagement 和 Carbon。

## 已知待办

- [x] 第一次 Xcode 静态编译
- [x] 定向单元测试通过（22 tests）
- [x] arm64 + x86_64 Debug build
- [ ] 运行时交互验收
- [ ] v2 动作切换与 16 向注视运行时验收
- [ ] 性能基线实测：空闲 CPU <1% / 跟随 <5% / 内存 <120MB
- [x] 正式尺寸 AppIcon（16px–1024px，商店提交前仍需最终品牌确认）
- [x] `AppStore` 沙盒配置、用户选择目录权限与 Privacy Manifest
- [x] 名称初筛：外部工作名 `FuzzOrbit` 为 `Conditional Go`；CNIPA、法律近似审查与 Apple 账号占位仍待完成
- [x] GitHub Pages 官网与 Preview Release 自动化
- [ ] Developer ID 签名 + 公证 + .dmg 打包脚本

## 许可

代码采用 [MIT License](LICENSE)。宠物素材请仅在拥有相应使用与再分发权时提交。
