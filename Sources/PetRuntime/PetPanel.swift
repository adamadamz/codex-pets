import AppKit
import SwiftUI

/// 桌面宠物的悬浮窗口。
///
/// 关键配置（PRD R-01）：
/// - .nonactivatingPanel：点宠物不抢焦点，不打断用户正在打的字
/// - .borderless + 透明背景：只看得见宠物本体
/// - level = .floating：浮于普通窗口之上（不用 .screenSaver，避免盖住系统弹窗）
/// - canJoinAllSpaces：切 Space 时宠物跟着走
/// - hidesOnDeactivate = false：App 失焦后宠物不消失
final class PetPanel: NSPanel {

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init(size: CGSize) {
        super.init(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        hidesOnDeactivate = false
        isMovableByWindowBackground = false   // 拖拽自己处理，避免与物理层抢位置
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        isReleasedWhenClosed = false
        animationBehavior = .none
        // 不出现在截屏/录屏之外的窗口列表里，也不参与 Mission Control 排布
        isExcludedFromWindowsMenu = true
    }
}

/// 把 PetConfig + 动态图集 + 物理层 + 窗口粘在一起的控制器
final class PetController {

    private(set) var config: PetConfig
    private let asset: DynamicPetAsset
    private let panel: PetPanel
    private let hosting: PetHostingView
    private let physics: PetPhysics
    private var renderState = PetRenderState()
    private var hasShown = false

    var onRequestMenu: ((NSPoint) -> Void)?

    init(config: PetConfig, asset: DynamicPetAsset) {
        self.config = config.clamped()
        self.asset = asset
        let size = self.config.renderSize
        self.panel = PetPanel(size: size)
        self.hosting = PetHostingView(frame: CGRect(origin: .zero, size: size))
        self.physics = PetPhysics(
            config: self.config,
            spriteVersionNumber: asset.contract.version
        )

        setupContent()
        wireEvents()
    }

    // MARK: - 组装

    private func setupContent() {
        hosting.wantsLayer = true
        let swiftUIHost = NSHostingView(rootView: petRootView())
        swiftUIHost.frame = hosting.bounds
        swiftUIHost.autoresizingMask = [.width, .height]
        hosting.addSubview(swiftUIHost)
        self.swiftUIHost = swiftUIHost
        panel.contentView = hosting
        panel.alphaValue = config.opacity
        panel.ignoresMouseEvents = config.clickThrough
    }

    private var swiftUIHost: NSHostingView<PetView>?

    private func petRootView() -> PetView {
        PetView(image: asset.frame(
                    row: renderState.spriteRow,
                    column: renderState.spriteColumn
                ),
                renderSize: config.renderSize,
                state: renderState)
    }

    private func wireEvents() {
        hosting.onMouseDown = { [weak self] p in self?.physics.beginDrag(at: p) }
        hosting.onMouseDragged = { [weak self] p in self?.physics.updateDrag(to: p) }
        hosting.onMouseUp = { [weak self] in self?.physics.endDrag() }

        hosting.onClick = { [weak self] count, local in
            guard let self else { return }
            if count >= 2 {
                self.hide()
            } else {
                self.physics.triggerClick(onHead: self.config.headHotZone
                    .contains(self.localToImagePoint(local)))
            }
        }

        hosting.onRightClick = { [weak self] p in self?.onRequestMenu?(p) }

        physics.onFrame = { [weak self] center, state in
            guard let self else { return }
            self.renderState = state
            let size = self.config.renderSize
            self.panel.setFrameOrigin(CGPoint(x: (center.x - size.width / 2).rounded(),
                                              y: (center.y - size.height / 2).rounded()))
            self.swiftUIHost?.rootView = self.petRootView()
        }
    }

    /// 窗口内坐标 → 原图坐标（用于 headHotZone 判定）
    private func localToImagePoint(_ p: NSPoint) -> CGPoint {
        let size = config.renderSize
        guard size.width > 0, size.height > 0 else { return .zero }
        return CGPoint(x: p.x / size.width * config.intrinsicSize.width,
                       y: p.y / size.height * config.intrinsicSize.height)
    }

    // MARK: - 对外操作

    func show() {
        let start = hasShown ? physics.center : initialCenter()
        physics.start(at: start)
        hasShown = true
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
        physics.stop()
    }

    var isVisible: Bool { panel.isVisible }

    func toggle() {
        if isVisible { hide() } else { show() }
    }

    func apply(_ new: PetConfig) {
        let c = new.clamped()
        let sizeChanged = c.renderSize != config.renderSize
        config = c
        physics.config = c
        panel.alphaValue = c.opacity
        panel.ignoresMouseEvents = c.clickThrough
        if sizeChanged {
            let center = CGPoint(x: panel.frame.midX, y: panel.frame.midY)
            panel.setContentSize(c.renderSize)
            swiftUIHost?.frame = CGRect(origin: .zero, size: c.renderSize)
            panel.setFrameOrigin(CGPoint(x: (center.x - c.renderSize.width / 2).rounded(),
                                         y: (center.y - c.renderSize.height / 2).rounded()))
        }
        swiftUIHost?.rootView = petRootView()
        physics.noteInteraction()
    }

    private func initialCenter() -> CGPoint {
        let f = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let s = config.renderSize
        let inset = config.initialInset
        switch config.initialAnchor {
        case .bottomTrailing: return CGPoint(x: f.maxX - s.width / 2 - inset,
                                             y: f.minY + s.height / 2 + inset)
        case .bottomLeading:  return CGPoint(x: f.minX + s.width / 2 + inset,
                                             y: f.minY + s.height / 2 + inset)
        case .topTrailing:    return CGPoint(x: f.maxX - s.width / 2 - inset,
                                             y: f.maxY - s.height / 2 - inset)
        case .topLeading:     return CGPoint(x: f.minX + s.width / 2 + inset,
                                             y: f.maxY - s.height / 2 - inset)
        case .center:         return CGPoint(x: f.midX, y: f.midY)
        }
    }
}
