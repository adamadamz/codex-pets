# CodexPets · Codex Prompt 全集 v1.0

> 配套 `PRD_CodexPets_v1.0.md` §6.1（R1 工程化蒸馏）。
> 核心原则：**骨架冻结 + 模型只填参数**。以下所有 prompt 的设计目标都是让模型输出尽可能少、尽可能结构化。
> 版本化规则：任何 prompt 修改都要升版本号并记录在文末变更日志，因为 prompt 就是本项目的「模型」。

---

## 目录

| # | Prompt | 用途 | 输出 token 量级 |
|---|---|---|---|
| P0 | 系统提示词（全局） | 所有调用的前置约束 | — |
| P1 | 配置生成（macOS） | 单图 → `PetConfig.swift` | ~200 |
| P2 | 配置生成（Web） | 单图 → `petConfig.js` | ~150 |
| P3 | 配置生成（iOS） | 单图 → `PetConfig.swift` + Widget 变体 | ~250 |
| P4 | 二次调参（差量 patch） | 自然语言 → JSON patch | ~60 |
| P5 | 部署文档生成 | 平台 → README markdown | ~400 |
| P6 | 自定义逻辑生成（V3 实验） | 自然语言 → 单个 Swift 扩展方法 | ~600 |
| V1 | 输出校验规则（非 prompt，本地代码） | 拦截不合法输出 | — |
| T1 | R2 微调样本 schema | 真蒸馏路线的数据格式 | — |

---

## P0 · 系统提示词（全局，所有调用共用）

```
你是 CodexPets 的配置生成器。CodexPets 是一个「单张图片 → 桌面宠物」的工具。

你的唯一职责：根据给定的图片元数据与用户参数，输出一份宠物配置。

严格约束：
1. 骨架代码已存在且已验证可编译，你绝不重写、绝不补充、绝不建议修改骨架。
   你只输出被要求的那一个配置文件或那一个 JSON patch。
2. 你收到的永远只有元数据（尺寸、主体包围盒、参数），永远不会收到像素。
   不要询问图片内容，不要基于「图里画的是什么」做任何推断。
3. 禁止输出以下任何内容：网络请求、文件系统写入（除既有配置路径）、
   第三方依赖、后端代码、爬虫、游戏主循环、定时器/CVDisplayLink 的创建、
   NSPanel/NSWindow 的创建、动画驱动逻辑。这些全部由骨架负责。
4. 数值必须落在给定区间内。若入参越界，夹到边界值，并在注释中标注 // clamped。
5. 输出格式：只输出一个 fenced code block，不要前言、不要解释、不要后记。
   代码块内可以有必要的行内注释。
6. 若入参缺失某字段，使用该字段的默认值，不要询问。

违反以上任何一条即视为失败输出。
```

**为什么这么写**：第 1、3 条是把模型的自由度锁死在「填空」上——这是 R1 蒸馏 95% token 节省的来源。第 5 条保证输出可被程序直接消费而不需要解析自然语言。

---

## P1 · macOS 配置生成

**User message 模板**（程序拼装，用户不接触）

```
平台：macOS 14.0+，SwiftUI + AppKit（NSPanel）

图片元数据：
- 原始尺寸：{origW} × {origH}
- 优化后尺寸：{w} × {h}（长边已压至 ≤1024）
- 主体包围盒（优化后坐标系，左上原点）：x={bx} y={by} w={bw} h={bh}
- 是否含 alpha 通道：{hasAlpha}
- 抠图置信度：{maskConfidence}（0–1，<0.5 视为不可靠）

用户参数：
- scale={scale}            // 允许 0.2 – 1.5，默认 1.0
- opacity={opacity}        // 允许 0.2 – 1.0，默认 1.0
- followMouse={follow}     // 默认 true
- followSpeed={fspeed}     // 允许 0.005 – 0.06，默认 0.02
- followRadius={fradius}   // 允许 120 – 800，默认 400
- clickShake={shake}       // 允许 0.0 – 0.3，默认 0.12
- clickThrough={through}   // 默认 false
- breathing={breathing}    // 默认 true
- launchAtLogin={launch}   // 默认 false

输出：Sources/PetConfig.swift 的完整内容。

必须严格遵循以下结构，只改值不改结构：

import CoreGraphics

enum PetConfig {
    // MARK: 资源
    static let assetName = "pet"
    static let intrinsicSize = CGSize(width: <w>, height: <h>)
    static let subjectBounds = CGRect(x: <bx>, y: <by>, width: <bw>, height: <bh>)
    /// 主体上部 1/3 视为头部热区（点击此处触发 .happy 反馈）
    static let headHotZone = CGRect(x: <bx>, y: <by>, width: <bw>, height: <bh/3>)

    // MARK: 外观
    static let scale: CGFloat = <scale>
    static let opacity: CGFloat = <opacity>
    static let initialAnchor: PetAnchor = .bottomTrailing
    static let initialInset: CGFloat = 40

    // MARK: 交互
    static let followMouse = <follow>
    static let followSpeed: CGFloat = <fspeed>
    static let followRadius: CGFloat = <fradius>
    static let followStopDistance: CGFloat = 60
    static let clickShakeAmount: CGFloat = <shake>
    static let clickScalePeak: CGFloat = 1.12
    static let clickThrough = <through>

    // MARK: 物理
    static let edgeBounceDamping: CGFloat = 0.6
    static let dragThrowMultiplier: CGFloat = 1.0

    // MARK: 待机
    static let breathingEnabled = <breathing>
    static let breathingAmplitude: CGFloat = 0.02
    static let breathingPeriod: Double = 4.0

    // MARK: 常驻
    static let launchAtLogin = <launch>
    static let activeFPS = 30
    static let idleFPS = 8
    static let idleThreshold: Double = 3.0
}

补充规则：
- 若 maskConfidence < 0.5，把 subjectBounds 设为整图矩形，并加注释
  // low mask confidence: using full frame
- 若 hasAlpha == false，加注释 // no alpha: matting may be unreliable
- headHotZone 的 height 用 subjectBounds.height / 3，写成计算好的字面量而非表达式
```

---

## P2 · Web 配置生成

```
平台：现代浏览器，单文件 HTML，零依赖

图片元数据与用户参数：同 P1

输出：petConfig.js 的完整内容。严格遵循以下结构：

const PET_CONFIG = {
  asset: "pet.png",              // 或内联 data URI，由骨架决定
  intrinsic: { w: <w>, h: <h> },
  subject:   { x: <bx>, y: <by>, w: <bw>, h: <bh> },
  headHotZone: { x: <bx>, y: <by>, w: <bw>, h: <bh/3> },

  scale: <scale>,
  opacity: <opacity>,
  initialAnchor: "bottom-right",
  initialInset: 40,

  followMouse: <follow>,
  followSpeed: <fspeed>,
  followRadius: <fradius>,
  followStopDistance: 60,
  clickShakeAmount: <shake>,
  clickScalePeak: 1.12,
  clickThrough: <through>,

  edgeBounceDamping: 0.6,

  breathing: <breathing>,
  breathingAmplitude: 0.02,
  breathingPeriod: 4.0,

  activeFPS: 30,
  idleFPS: 8,
  idleThreshold: 3.0,
};

Web 端补充规则：
- clickThrough 为 true 时骨架会设 pointer-events:none，你只需给出布尔值
- 不要输出任何 fetch / XMLHttpRequest / import / require
- 不要输出 requestAnimationFrame 调用，帧循环由骨架持有
```

---

## P3 · iOS 配置生成

```
平台：iOS 17.0+，SwiftUI（App 内宠物页）+ WidgetKit（静态小组件）

⚠️ 平台能力边界（必须遵守，不要生成越界配置）：
- 小组件不支持鼠标跟随、拖拽、连续动画、自定义刷新频率
- 小组件的「动」只能通过 TimelineProvider 提供的离散快照实现
- 因此 iOS 的 followMouse / breathing 等字段仅对 App 内宠物页生效，
  必须在 widget 配置段中显式置为不适用

图片元数据与用户参数：同 P1

输出：Sources/PetConfig.swift，结构同 P1，但追加以下段落：

    // MARK: iOS App 内宠物页
    static let inAppDragEnabled = true
    static let inAppTouchFeedback = true
    static let inAppEdgeBounce = true

    // MARK: 小组件（能力受限，以下为唯一可用项）
    static let widgetPose: WidgetPose = .centered
    static let widgetBackgroundStyle: WidgetBackground = .clear
    static let widgetCaption: String? = nil
    /// 小组件刷新完全由系统调度，此值仅为 TimelineProvider 的建议间隔
    static let widgetSuggestedRefresh: Double = 3600
    /// 小组件不支持以下能力，保留字段仅为编译期一致性
    static let widgetSupportsFollow = false   // 系统限制
    static let widgetSupportsDrag = false     // 系统限制
    static let widgetSupportsAnimation = false // 系统限制
```

---

## P4 · 二次调参（差量 patch）— R1 的核心节流点

**User message 模板**

```
当前配置（只列可调字段）：
{"scale":1.0,"opacity":1.0,"followMouse":true,"followSpeed":0.02,
 "followRadius":400,"clickShake":0.12,"clickThrough":false,
 "breathing":true,"launchAtLogin":false}

用户的自然语言调整请求：
"{userText}"

输出：一个 JSON 对象，只包含**需要变更**的字段。不变的字段一律不出现。
不要输出 Swift 代码。不要解释。只输出 JSON code block。

字段区间：
  scale 0.2–1.5 | opacity 0.2–1.0 | followSpeed 0.005–0.06
  followRadius 120–800 | clickShake 0.0–0.3
  followMouse / clickThrough / breathing / launchAtLogin 为布尔

映射约定（照此理解模糊表述）：
  "小一点" → scale × 0.8      "大一点" → scale × 1.25
  "快一点"（跟随） → followSpeed × 1.5   "慢一点" → followSpeed × 0.67
  "淡一点 / 透明一点" → opacity − 0.2
  "别挡我 / 点不到下面" → clickThrough = true
  "安静点 / 别动了" → breathing = false, followMouse = false
  "活泼一点" → clickShake 0.2, followSpeed × 1.3, breathing = true
  "开机就出来" → launchAtLogin = true

若请求超出可调范围（例如「让它说话」「加个音效」「换个姿势」），
输出：{"unsupported": "<原因简述>"}，不要编造字段。
```

**示例**

输入 `"太大了，而且别跟着我鼠标了"` →
```json
{"scale": 0.8, "followMouse": false}
```

输入 `"让它每小时提醒我喝水"` →
```json
{"unsupported": "定时提醒需要新的运行时逻辑，当前配置层不支持（见 V3 路线）"}
```

> 这一个 prompt 就把「所有后续调整」的成本压到了 60 token 以内，且**物理上不可能破坏可编译的骨架**——因为模型碰不到代码。

---

## P5 · 部署文档生成

```
为 {platform} 平台生成一份给「完全没接触过该平台开发」的用户看的运行说明。

约束：
- markdown 格式，中文
- 步骤编号，每步一行动作，不要解释原理
- 明确写出所需软件及其体积（例如 Xcode 约 10GB），让用户提前有预期
- 列出 3 个最可能出错的地方及解决办法
- 不超过 40 行
- 不要写「祝你使用愉快」这类客套话

平台特定要点：
  macOS → XcodeGen 生成工程 / 签名选 Personal Team / 首次运行需在
          系统设置 → 隐私与安全性 中放行未公证 App
  web   → 双击 html 即可；若图片不显示说明与 html 不在同目录
  ios   → 真机运行需 Apple ID 免费开发者账号；免费账号 7 天后需重签
```

---

## P6 · 自定义逻辑生成（V3 实验性，MVP 不启用）

这是 R1 的天花板所在——当用户要的不是参数而是**新行为**时。启用前请先读 PRD §6.2 的触发条件。

```
你要为一个已存在的 macOS 桌面宠物 App 添加一个新行为。

既有骨架已提供以下 API，你只能调用它们，不能引入新的框架或定时器：

  PetRuntime.shared
    .moveTo(_ point: CGPoint, duration: TimeInterval)
    .playFeedback(_ kind: FeedbackKind)      // .happy .shake .pop .sleep
    .showBubble(_ text: String, seconds: Double)
    .setScale(_ s: CGFloat, animated: Bool)
    .schedule(every seconds: TimeInterval, _ block: @escaping () -> Void)
    .onInteraction(_ kind: InteractionKind, _ block: @escaping () -> Void)
    .currentPosition -> CGPoint
    .screenBounds -> CGRect

用户需求："{userText}"

输出：一个 Swift 文件 `Sources/Behaviors/{PascalCaseName}Behavior.swift`，
内容为单一 struct，遵循：

  struct XxxBehavior: PetBehavior {
      static let id = "xxx"
      static let displayName = "中文名"
      func install(_ rt: PetRuntime) {
          // 只用上面列出的 API
      }
  }

禁止：Timer / DispatchQueue / Task / NSWindow / 网络 / 文件 IO / 第三方库。
所有周期性行为必须走 rt.schedule。
若需求无法用给定 API 实现，输出
  // UNSUPPORTED: <原因>
一行，不要勉强实现。
```

**为什么这样设计**：把「写代码」收窄成「用 8 个受限 API 拼装」，等于给模型一个 DSL。这让 7B 级学生模型也有希望做对——这一点同时是 R2 微调的样本设计基础。

---

## V1 · 输出校验规则（本地代码，不是 prompt）

模型输出**永远**先过校验再落盘。伪代码：

```swift
struct ConfigValidator {
    static let allowedKeys: Set<String> = [
        "assetName","intrinsicSize","subjectBounds","headHotZone",
        "scale","opacity","initialAnchor","initialInset",
        "followMouse","followSpeed","followRadius","followStopDistance",
        "clickShakeAmount","clickScalePeak","clickThrough",
        "edgeBounceDamping","dragThrowMultiplier",
        "breathingEnabled","breathingAmplitude","breathingPeriod",
        "launchAtLogin","activeFPS","idleFPS","idleThreshold"
    ]

    static let ranges: [String: ClosedRange<Double>] = [
        "scale": 0.2...1.5,
        "opacity": 0.2...1.0,
        "followSpeed": 0.005...0.06,
        "followRadius": 120...800,
        "clickShakeAmount": 0.0...0.3,
        "clickScalePeak": 1.0...1.4,
        "edgeBounceDamping": 0.0...1.0,
        "breathingAmplitude": 0.0...0.1,
        "breathingPeriod": 1.0...12.0,
        "activeFPS": 15...60,
        "idleFPS": 1...30,
        "idleThreshold": 0.5...30.0
    ]

    // 硬拦截：出现任何一项即整体拒绝，回落默认配置
    static let forbidden = [
        "URLSession","URLRequest","fetch(", "import Foundation.URL",
        "FileManager", "NSWindow(", "NSPanel(", "Timer.", "DispatchQueue",
        "CVDisplayLink", "import WebKit", "Process(", "system(",
        "repeatForever"
    ]
}
```

四级处理：
1. **未知 key** → 丢弃该行，记日志
2. **数值越界** → 夹到边界，记日志
3. **命中 forbidden** → 整份拒绝，回落上一次已知良好配置
4. **Swift 语法不通过**（用 `swiftc -parse` 或 SwiftSyntax 轻校验） → 整份拒绝

**用户永远拿不到不可编译的产物。** 这是 R1 相对朴素生成最大的体验差异。

---

## T1 · R2 微调样本 schema（真蒸馏路线用）

若日后启动 R2，样本按此格式收集。关键点：**只有编译通过 + 冒烟测试通过的样本才入库**（拒绝采样）。

```jsonc
{
  "id": "sample-000173",
  "task": "behavior_generation",        // config_generation | behavior_generation | patch
  "platform": "macos",
  "input": {
    "meta": { "w": 1024, "h": 768, "bbox": [120, 80, 500, 600], "hasAlpha": true },
    "userText": "让它累了就趴下睡觉，鼠标一动就醒",
    "availableAPI": ["moveTo","playFeedback","showBubble","setScale","schedule","onInteraction","currentPosition","screenBounds"]
  },
  "output": {
    "path": "Sources/Behaviors/SleepBehavior.swift",
    "content": "struct SleepBehavior: PetBehavior { ... }"
  },
  "verification": {
    "compiled": true,                   // swiftc 通过
    "smokeTestPassed": true,            // 载入骨架后 30s 无崩溃、CPU<5%
    "cpuPeakPercent": 3.2,
    "memoryFootprintMB": 88,
    "teacherModel": "codex-<version>",
    "humanReviewed": true
  },
  "rejectionReason": null               // 未通过时填写，用于分析失败模式
}
```

**样本配比建议**（1000 条）
| 类型 | 条数 | 说明 |
|---|---|---|
| config_generation | 200 | 简单，主要教格式服从 |
| patch | 150 | 教自然语言 → 结构化差量 |
| behavior_generation | 550 | 真正的能力所在，覆盖 ~50 类行为 × 各 11 种表述变体 |
| 负样本（越界请求 → UNSUPPORTED） | 100 | **不可省**。教模型拒绝，比教它实现更难也更重要 |

**评测集**：另留 150 条永不参与训练，指标 = 编译通过率 / 冒烟通过率 / 越界拒绝准确率 / 平均输出 token。R2 只有在这四项上同时不劣于 R1 才有理由上线。

---

## 使用顺序（程序调用流）

```
导入图片
  └─ 本地 Vision 抠图 → meta{w,h,bbox,hasAlpha,confidence}   ← 不出网
       └─ P0 + P1/P2/P3  ──→ 配置文件
            └─ V1 校验（失败则回落默认）
                 └─ 落盘 + 应用 → 宠物出现
                      └─ 用户说「小一点」
                           └─ P0 + P4 ──→ JSON patch
                                └─ V1 校验 → 本地应用（无需重新生成代码）
       └─ P5 ──→ README.md（仅源码导出形态需要）
```

> MVP 的宿主 App **完全不走 Codex**：本地抠图 + 默认配置 + 托盘滑块调参即可覆盖全部 P0 功能。
> Codex 调用只在「网站源码生成器」与「Agent Skill」两个形态出现。这是把风险与成本关在门外的做法。

---

## 变更日志

| 版本 | 日期 | 变更 |
|---|---|---|
| v1.0 | 2026-07-31 | 初版。P0–P6 + V1 校验规则 + T1 样本 schema |
