import SwiftUI

/// 纯展示层。所有随时间变化的量都从 PetPhysics 传进来。
/// 这里刻意不启动任何 SwiftUI 自驱动动画 —— 见 PetPhysics 的注释。
struct PetView: View {
    let image: NSImage
    let renderSize: CGSize
    let state: PetRenderState

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)   // 等比，永不拉伸变形
            .frame(width: renderSize.width, height: renderSize.height)
            .scaleEffect(state.scaleMultiplier, anchor: .bottom)
            .rotationEffect(.degrees(state.rotationDegrees), anchor: .bottom)
            .offset(y: state.verticalOffset)
            .allowsHitTesting(false)          // 命中判定统一交给 PetPanel
    }
}

/// 承载 PetView 的 NSView：负责鼠标事件，不参与渲染
final class PetHostingView: NSView {

    var onMouseDown: ((NSPoint) -> Void)?
    var onMouseDragged: ((NSPoint) -> Void)?
    var onMouseUp: (() -> Void)?
    var onClick: ((_ clickCount: Int, _ localPoint: NSPoint) -> Void)?
    var onRightClick: ((NSPoint) -> Void)?

    private var dragDistance: CGFloat = 0
    private var downLocation: NSPoint = .zero

    override var isFlipped: Bool { true }   // 左上原点，与 headHotZone 坐标系一致

    override func mouseDown(with event: NSEvent) {
        downLocation = convert(event.locationInWindow, from: nil)
        dragDistance = 0
        onMouseDown?(NSEvent.mouseLocation)
    }

    override func mouseDragged(with event: NSEvent) {
        dragDistance += abs(event.deltaX) + abs(event.deltaY)
        onMouseDragged?(NSEvent.mouseLocation)
    }

    override func mouseUp(with event: NSEvent) {
        onMouseUp?()
        // 位移小于 4pt 才算「点击」而不是「拖拽」
        if dragDistance < 4 {
            onClick?(event.clickCount, downLocation)
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?(NSEvent.mouseLocation)
    }
}
