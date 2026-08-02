import CoreGraphics

/// 宠物锚点（初始出现位置）
enum PetAnchor: String, Codable {
    case bottomTrailing, bottomLeading, topTrailing, topLeading, center
}

/// 唯一由生成器（Codex / 托盘滑块）写入的配置层。
/// 骨架代码只读取这里，不反向修改。
/// 对应 Prompt_Pack_v1.0.md 的 P1 输出结构。
struct PetConfig: Codable, Equatable {

    // MARK: 资源
    /// 已复制到 App Support/CodexPets/pets/ 下的动态宠物 ID。
    /// nil 表示尚未选择动态宠物；旧版 config.json 缺少此字段时可正常迁移。
    var selectedPetID: String?
    var assetFileName: String = "pet.png"
    var intrinsicSize: CGSize = CGSize(width: 512, height: 512)
    var subjectBounds: CGRect = CGRect(x: 0, y: 0, width: 512, height: 512)
    /// 主体上部 1/3，点击此处触发 .happy 反馈
    var headHotZone: CGRect = CGRect(x: 0, y: 0, width: 512, height: 170)

    // MARK: 外观
    var scale: CGFloat = 1.0            // 0.2 – 1.5
    var opacity: CGFloat = 1.0          // 0.2 – 1.0
    var initialAnchor: PetAnchor = .bottomTrailing
    var initialInset: CGFloat = 40

    // MARK: 交互
    var followMouse: Bool = true
    var followSpeed: CGFloat = 0.02     // 0.005 – 0.06
    var followRadius: CGFloat = 400     // 120 – 800
    var followStopDistance: CGFloat = 60
    var clickShakeAmount: CGFloat = 0.12 // 0.0 – 0.3
    var clickScalePeak: CGFloat = 1.12
    var clickThrough: Bool = false

    // MARK: 物理
    var edgeBounceDamping: CGFloat = 0.6
    var dragThrowMultiplier: CGFloat = 1.0

    // MARK: 待机
    var breathingEnabled: Bool = true
    var breathingAmplitude: CGFloat = 0.02
    var breathingPeriod: Double = 4.0

    // MARK: 常驻与帧率
    var launchAtLogin: Bool = false
    var activeFPS: Int = 30
    var idleFPS: Int = 8
    var idleThreshold: Double = 3.0

    /// 渲染尺寸（等比，不拉伸）
    var renderSize: CGSize {
        let longSide = max(intrinsicSize.width, intrinsicSize.height)
        guard longSide > 0 else { return CGSize(width: 200, height: 200) }
        // 基准：长边 260pt @ scale 1.0
        let factor = 260.0 / longSide * scale
        return CGSize(width: (intrinsicSize.width * factor).rounded(),
                      height: (intrinsicSize.height * factor).rounded())
    }
}

// MARK: - 校验（对应 Prompt_Pack V1 规则）

extension PetConfig {
    /// 把所有数值夹到合法区间。生成器写入前必过此关。
    func clamped() -> PetConfig {
        var c = self
        func clamp(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat { min(max(v, lo), hi) }
        c.scale             = clamp(c.scale, 0.2, 1.5)
        c.opacity           = clamp(c.opacity, 0.2, 1.0)
        c.followSpeed       = clamp(c.followSpeed, 0.005, 0.06)
        c.followRadius      = clamp(c.followRadius, 120, 800)
        c.followStopDistance = clamp(c.followStopDistance, 20, 200)
        c.clickShakeAmount  = clamp(c.clickShakeAmount, 0.0, 0.3)
        c.clickScalePeak    = clamp(c.clickScalePeak, 1.0, 1.4)
        c.edgeBounceDamping = clamp(c.edgeBounceDamping, 0.0, 1.0)
        c.breathingAmplitude = clamp(c.breathingAmplitude, 0.0, 0.1)
        c.breathingPeriod   = min(max(c.breathingPeriod, 1.0), 12.0)
        c.activeFPS         = min(max(c.activeFPS, 15), 60)
        c.idleFPS           = min(max(c.idleFPS, 1), 30)
        c.idleThreshold     = min(max(c.idleThreshold, 0.5), 30.0)
        return c
    }
}
