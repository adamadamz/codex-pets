import AppKit
import Carbon.HIToolbox

enum HotKeyAction: UInt32, CaseIterable {
    case toggleVisibility = 1
    case recoverInteraction = 2
}

struct HotKeyBinding: Equatable {
    let action: HotKeyAction
    let keyCode: UInt32
    let modifiers: UInt32

    static let defaults = [
        HotKeyBinding(
            action: .toggleVisibility,
            keyCode: UInt32(kVK_ANSI_P),
            modifiers: UInt32(optionKey | cmdKey)
        ),
        HotKeyBinding(
            action: .recoverInteraction,
            keyCode: UInt32(kVK_ANSI_P),
            modifiers: UInt32(optionKey | cmdKey | shiftKey)
        )
    ]
}

/// 全局快捷键：⌥⌘P 显示/隐藏，⇧⌥⌘P 关闭点击穿透并恢复宠物。
///
/// 用 Carbon 的 RegisterEventHotKey 而不是 NSEvent.addGlobalMonitorForEvents —— 后者
/// 需要「辅助功能」授权，对一个桌面挂件来说是过重的权限请求，会掉转化。
final class HotKeyCenter {

    static let shared = HotKeyCenter()
    private init() {}

    var onToggleVisibility: (() -> Void)?
    var onRecoverInteraction: (() -> Void)?

    private static let signature = OSType(0x43_50_54_53) // 'CPTS'

    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var eventHandler: EventHandlerRef?

    var registeredActions: Set<HotKeyAction> {
        Set(hotKeyRefs.keys.compactMap(HotKeyAction.init(rawValue:)))
    }

    func register(bindings: [HotKeyBinding] = HotKeyBinding.defaults) {
        unregister()

        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                guard let action = HotKeyCenter.action(from: event) else {
                    return OSStatus(eventNotHandledErr)
                }
                HotKeyCenter.shared.dispatch(action)
                return noErr
            },
            1, &spec, nil, &eventHandler
        )
        guard handlerStatus == noErr else {
            NSLog("[CodexPets] 全局快捷键事件处理器安装失败，status=\(handlerStatus)")
            eventHandler = nil
            return
        }

        for binding in bindings {
            var ref: EventHotKeyRef?
            let id = EventHotKeyID(signature: Self.signature, id: binding.action.rawValue)
            let status = RegisterEventHotKey(
                binding.keyCode,
                binding.modifiers,
                id,
                GetApplicationEventTarget(),
                0,
                &ref
            )
            if status == noErr, let ref {
                hotKeyRefs[binding.action.rawValue] = ref
            } else {
                NSLog("[CodexPets] 快捷键 \(binding.action) 注册失败（可能已被其他 App 占用），status=\(status)")
            }
        }
    }

    func unregister() {
        for ref in hotKeyRefs.values { UnregisterEventHotKey(ref) }
        hotKeyRefs.removeAll()
        if let h = eventHandler { RemoveEventHandler(h); eventHandler = nil }
    }

    private static func action(from event: EventRef?) -> HotKeyAction? {
        guard let event else { return nil }
        var id = EventHotKeyID(signature: 0, id: 0)
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &id
        )
        guard status == noErr, id.signature == signature else { return nil }
        return HotKeyAction(rawValue: id.id)
    }

    private func dispatch(_ action: HotKeyAction) {
        switch action {
        case .toggleVisibility:
            onToggleVisibility?()
        case .recoverInteraction:
            onRecoverInteraction?()
        }
    }
}
