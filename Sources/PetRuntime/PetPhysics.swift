import AppKit
import QuartzCore

/// 宠物的渲染状态（每帧由物理层算好，交给 SwiftUI 纯展示）
struct PetRenderState: Equatable {
    var scaleMultiplier: CGFloat = 1.0
    var rotationDegrees: Double = 0
    var verticalOffset: CGFloat = 0
    var spriteRow: Int = 0
    var spriteColumn: Int = 0
}

enum PetMotionMode { case idle, dragging, following }

/// 全 App 唯一的动画时钟。
///
/// 为什么只允许有一个：两套动画时钟（物理定时器 + SwiftUI 自驱动循环）
/// 叠加是桌面宠物类 App CPU 飙升的头号原因。SwiftUI 侧只做声明式渲染，
/// 所有随时间变化的量都在这里算完。
///
/// 空闲 idleThreshold 秒后降到 idleFPS，鼠标一动立刻升回 activeFPS。
final class PetPhysics {

    // MARK: 对外
    var config: PetConfig
    /// 每帧回调：(宠物中心点-屏幕坐标, 渲染状态)
    var onFrame: ((CGPoint, PetRenderState) -> Void)?
    let spriteVersionNumber: Int

    private(set) var mode: PetMotionMode = .idle
    private(set) var center: CGPoint = .zero

    // MARK: 内部状态
    private var velocity: PetVelocity = PetVelocity(dx: 0, dy: 0)
    private var timer: Timer?
    private var currentFPS: Int = 0
    private var lastInteraction: CFTimeInterval = CACurrentMediaTime()
    private var lastTickTime: CFTimeInterval?
    private var elapsed: Double = 0
    private var animationState: PetAnimationState = .idle
    private var animationFrameIndex = 0
    private var animationFrameElapsedMilliseconds: Double = 0
    private var transientAnimation: PetAnimationState?
    private var horizontalIntent: CGFloat = 1

    /// 点击反馈：一个衰减的弹簧脉冲，0 表示无反馈
    private var clickImpulse: CGFloat = 0
    private var clickImpulseVelocity: CGFloat = 0
    private var shakePhase: Double = 0
    private var shakeEnergy: CGFloat = 0

    private var dragOrigin: CGPoint = .zero
    private var lastDragPoint: CGPoint = .zero
    private var lastDragTime: CFTimeInterval = 0

    init(config: PetConfig, spriteVersionNumber: Int = 1) {
        self.config = config
        self.spriteVersionNumber = spriteVersionNumber
    }

    deinit { stop() }

    // MARK: - 生命周期

    func start(at point: CGPoint) {
        center = point
        mode = .idle
        lastInteraction = CACurrentMediaTime()
        lastTickTime = CACurrentMediaTime()
        resetAnimation(to: .idle)
        transientAnimation = .waving
        setFPS(config.activeFPS)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        currentFPS = 0
        lastTickTime = nil
        mode = .idle
        velocity = PetVelocity(dx: 0, dy: 0)
        clickImpulse = 0
        clickImpulseVelocity = 0
        shakeEnergy = 0
        transientAnimation = nil
        resetAnimation(to: .idle)
    }

    private func setFPS(_ fps: Int) {
        guard fps != currentFPS else { return }
        currentFPS = fps
        timer?.invalidate()
        lastTickTime = CACurrentMediaTime()
        let t = Timer(timeInterval: 1.0 / Double(fps), repeats: true) { [weak self] _ in
            self?.tick()
        }
        // .common 模式：拖窗口、滚动菜单时动画不停
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    // MARK: - 交互输入

    func noteInteraction() {
        lastInteraction = CACurrentMediaTime()
        setFPS(config.activeFPS)
    }

    func beginDrag(at screenPoint: CGPoint) {
        mode = .dragging
        dragOrigin = CGPoint(x: screenPoint.x - center.x, y: screenPoint.y - center.y)
        lastDragPoint = screenPoint
        lastDragTime = CACurrentMediaTime()
        velocity = PetVelocity(dx: 0, dy: 0)
        noteInteraction()
    }

    func updateDrag(to screenPoint: CGPoint) {
        guard mode == .dragging else { return }
        center = CGPoint(x: screenPoint.x - dragOrigin.x, y: screenPoint.y - dragOrigin.y)
        let now = CACurrentMediaTime()
        let dt = max(now - lastDragTime, 1.0 / 120.0)
        velocity = PetVelocity(
            dx: (screenPoint.x - lastDragPoint.x) / CGFloat(dt * PetMotionMath.referenceFPS),
            dy: (screenPoint.y - lastDragPoint.y) / CGFloat(dt * PetMotionMath.referenceFPS)
        )
        let dx = screenPoint.x - lastDragPoint.x
        if abs(dx) > 0.1 { horizontalIntent = dx }
        lastDragPoint = screenPoint
        lastDragTime = now
        noteInteraction()
    }

    func endDrag() {
        guard mode == .dragging else { return }
        // 甩出去：保留一部分速度让边缘回弹看得见
        velocity.dx *= config.dragThrowMultiplier
        velocity.dy *= config.dragThrowMultiplier
        mode = .idle
        noteInteraction()
    }

    /// 点击反馈：注入一个弹簧脉冲 + 抖动能量
    func triggerClick(onHead: Bool) {
        clickImpulse = config.clickScalePeak - 1.0
        clickImpulseVelocity = 0
        shakeEnergy = config.clickShakeAmount * (onHead ? 1.4 : 1.0)
        shakePhase = 0
        transientAnimation = .jumping
        resetAnimation(to: .jumping)
        noteInteraction()
    }

    // MARK: - 主循环

    private func tick() {
        let now = CACurrentMediaTime()
        let rawDelta = now - (lastTickTime ?? now)
        lastTickTime = now
        elapsed += max(rawDelta, 0)
        let dt = PetMotionMath.simulationDelta(from: rawDelta)

        // 1. 移动
        switch mode {
        case .dragging:
            break // 位置由 updateDrag 直接写入
        case .idle, .following:
            applyFollowOrInertia(dt: dt)
        }

        // 2. 边缘回弹
        applyEdgeBounce()

        // 3. 渲染状态
        let state = renderState(dt: dt)

        // 4. 提交
        onFrame?(center, state)

        // 5. 降频
        let quiet = now - lastInteraction > config.idleThreshold
        let stillMoving = abs(velocity.dx) > 0.3 || abs(velocity.dy) > 0.3
            || clickImpulse != 0 || shakeEnergy > 0.001
        if quiet && !stillMoving && mode != .dragging {
            setFPS(config.idleFPS)
        }
    }

    private func applyFollowOrInertia(dt: Double) {
        var didFollow = false

        if config.followMouse {
            let mouse = NSEvent.mouseLocation
            let dx = mouse.x - center.x
            let dy = mouse.y - center.y
            let dist = (dx * dx + dy * dy).squareRoot()

            if dist < config.followRadius && dist > config.followStopDistance {
                // 缓动靠近：速度 ∝ 距离，天然不会越过目标
                let step = PetMotionMath.approachFraction(
                    perReferenceFrame: config.followSpeed,
                    deltaTime: dt
                )
                center.x += dx * step
                center.y += dy * step
                mode = .following
                if abs(dx) > 0.1 { horizontalIntent = dx }
                didFollow = true
                lastInteraction = CACurrentMediaTime()
                if currentFPS != config.activeFPS { setFPS(config.activeFPS) }
            }
        }

        if !didFollow {
            if mode == .following { mode = .idle }
            // 惯性 + 阻尼
            let factors = PetMotionMath.inertiaFactors(
                dampingPerReferenceFrame: 0.94,
                deltaTime: dt
            )
            center.x += velocity.dx * factors.travel
            center.y += velocity.dy * factors.travel
            if abs(velocity.dx) > 0.1 { horizontalIntent = velocity.dx }
            velocity.dx *= factors.remainingVelocity
            velocity.dy *= factors.remainingVelocity
            if abs(velocity.dx) < 0.05 { velocity.dx = 0 }
            if abs(velocity.dy) < 0.05 { velocity.dy = 0 }
        }
    }

    private func applyEdgeBounce() {
        let size = config.renderSize
        guard let frame = currentScreenFrame() else { return }
        let halfW = size.width / 2, halfH = size.height / 2
        let damping = config.edgeBounceDamping

        if center.x - halfW < frame.minX {
            center.x = frame.minX + halfW
            if velocity.dx < 0 { velocity.dx = -velocity.dx * damping }
        }
        if center.x + halfW > frame.maxX {
            center.x = frame.maxX - halfW
            if velocity.dx > 0 { velocity.dx = -velocity.dx * damping }
        }
        if center.y - halfH < frame.minY {
            center.y = frame.minY + halfH
            if velocity.dy < 0 { velocity.dy = -velocity.dy * damping }
        }
        if center.y + halfH > frame.maxY {
            center.y = frame.maxY - halfH
            if velocity.dy > 0 { velocity.dy = -velocity.dy * damping }
        }
    }

    /// 优先使用中心点所在屏幕；中心在屏幕外时按相交面积或最近距离选择。
    private func currentScreenFrame() -> CGRect? {
        let screens = NSScreen.screens
        guard let index = PetScreenGeometry.bestScreenIndex(
            for: center,
            petSize: config.renderSize,
            screenFrames: screens.map(\.frame)
        ) else {
            return NSScreen.main?.visibleFrame
        }
        return screens[index].visibleFrame
    }

    private func renderState(dt: Double) -> PetRenderState {
        var s = PetRenderState()
        let sprite = currentSpriteFrame(deltaTime: dt)
        s.spriteRow = sprite.row
        s.spriteColumn = sprite.column

        // 呼吸：尊重系统「减弱动态效果」
        if config.breathingEnabled && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            let phase = elapsed / config.breathingPeriod * 2 * .pi
            s.scaleMultiplier += config.breathingAmplitude * CGFloat(sin(phase))
            s.verticalOffset = CGFloat(sin(phase)) * 1.5
        }

        // 点击弹簧：临界阻尼，快去快回，连击不叠加（脉冲被重置而非累加）
        if clickImpulse != 0 || clickImpulseVelocity != 0 {
            let stiffness: CGFloat = 320
            let damping: CGFloat = 26
            let steps = max(1, Int(ceil(dt * 120)))
            let step = CGFloat(dt) / CGFloat(steps)
            for _ in 0..<steps {
                let accel = -stiffness * clickImpulse - damping * clickImpulseVelocity
                clickImpulseVelocity += accel * step
                clickImpulse += clickImpulseVelocity * step
            }
            if abs(clickImpulse) < 0.001 && abs(clickImpulseVelocity) < 0.01 {
                clickImpulse = 0; clickImpulseVelocity = 0
            }
            s.scaleMultiplier += clickImpulse
        }

        // 抖动：衰减正弦
        if shakeEnergy > 0.001 {
            shakePhase += dt * 26
            s.rotationDegrees = Double(shakeEnergy) * 40 * sin(shakePhase)
            shakeEnergy *= CGFloat(pow(0.02, dt)) // ~每 0.2s 衰减一个数量级
        } else {
            shakeEnergy = 0
        }

        return s
    }

    private func currentSpriteFrame(deltaTime: Double) -> PetSpriteFrame {
        if transientAnimation == nil,
           mode == .idle,
           abs(velocity.dx) < 0.3,
           abs(velocity.dy) < 0.3 {
            let size = config.renderSize
            let frame = CGRect(
                x: center.x - size.width / 2,
                y: center.y - size.height / 2,
                width: size.width,
                height: size.height
            )
            if let look = PetLookDirection.frame(
                petFrame: frame,
                pointer: NSEvent.mouseLocation,
                spriteVersionNumber: spriteVersionNumber
            ) {
                resetAnimation(to: .idle)
                return look
            }
        }

        let target = transientAnimation ?? movementAnimationState()
        if target != animationState { resetAnimation(to: target) }
        let sequence = animationState.frames
        guard !sequence.isEmpty else {
            return PetSpriteFrame(row: 0, column: 0, durationMilliseconds: 0)
        }

        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            let stillFrame = sequence[0]
            if transientAnimation != nil {
                transientAnimation = nil
                resetAnimation(to: movementAnimationState())
            }
            return stillFrame
        }

        animationFrameElapsedMilliseconds += max(deltaTime, 0) * 1_000
        while animationFrameElapsedMilliseconds
            >= sequence[animationFrameIndex].durationMilliseconds {
            animationFrameElapsedMilliseconds
                -= sequence[animationFrameIndex].durationMilliseconds
            animationFrameIndex += 1
            if animationFrameIndex >= sequence.count {
                if transientAnimation != nil {
                    transientAnimation = nil
                    resetAnimation(to: movementAnimationState())
                    return animationState.frames[0]
                }
                animationFrameIndex = 0
            }
        }
        return animationState.frames[animationFrameIndex]
    }

    private func movementAnimationState() -> PetAnimationState {
        let moving = mode == .dragging || mode == .following
            || abs(velocity.dx) > 0.3 || abs(velocity.dy) > 0.3
        guard moving else { return .idle }
        return horizontalIntent < 0 ? .runningLeft : .runningRight
    }

    private func resetAnimation(to state: PetAnimationState) {
        animationState = state
        animationFrameIndex = 0
        animationFrameElapsedMilliseconds = 0
    }
}

/// 自己定义而不用 CGVector：SpriteKit 也声明了 CGVector，
/// 日后若有人 import SpriteKit 会撞名。
struct PetVelocity {
    var dx: CGFloat
    var dy: CGFloat
}
