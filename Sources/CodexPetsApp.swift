import AppKit

enum PetInteractionRecovery {
    static func recoveredConfig(from config: PetConfig) -> PetConfig {
        var recovered = config
        recovered.clickThrough = false
        return recovered
    }
}

/// 菜单栏常驻 App。
/// 刻意不用 SwiftUI 的 App/Scene 生命周期 —— 一个 accessory 级别的 agent app
/// 用 AppKit 直接管理 NSPanel 与 NSStatusItem 更可控，也不会被 Scene 系统
/// 偷偷创建出多余的窗口。
@main
struct CodexPetsMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)   // 不进 Dock、不进 Cmd-Tab
        app.run()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var tray: TrayController?
    private var pet: PetController?
    private var petPickerWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupTray()
        setupHotKey()

        if PetStore.shared.hasPet {
            showPet()
        } else {
            openPetPicker()
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    // MARK: - 托盘

    private func setupTray() {
        let t = TrayController()
        t.onToggleVisibility = { [weak self] in self?.togglePet() }
        t.onRecoverInteraction = { [weak self] in self?.recoverPetInteraction() }
        t.onSelectPet = { [weak self] in self?.openPetPicker() }
        t.onConfigChanged = { [weak self] config in self?.pet?.apply(config) }
        t.isPetVisible = { [weak self] in self?.pet?.isVisible ?? false }
        tray = t
    }

    private func setupHotKey() {
        HotKeyCenter.shared.onToggleVisibility = { [weak self] in self?.togglePet() }
        HotKeyCenter.shared.onRecoverInteraction = { [weak self] in self?.recoverPetInteraction() }
        HotKeyCenter.shared.register()
    }

    // MARK: - 宠物

    private func showPet() {
        guard let asset = PetStore.shared.loadPetAsset() else {
            openPetPicker()
            return
        }
        pet?.hide()
        let controller = PetController(config: PetStore.shared.config, asset: asset)
        // 右键宠物 = 弹出托盘菜单，不另做一套菜单
        controller.onRequestMenu = { [weak self] _ in self?.tray?.openMenu() }
        controller.show()
        pet = controller
    }

    private func togglePet() {
        if let pet {
            pet.toggle()
        } else {
            showPet()
        }
    }

    /// 点击穿透时宠物本体不再接收鼠标；该路径必须只依赖菜单栏或 Carbon 热键。
    private func recoverPetInteraction() {
        let current = PetStore.shared.config
        if current.clickThrough {
            let recovered = PetInteractionRecovery.recoveredConfig(from: current)
            let stored = PetStore.shared.updateConfig(recovered)
            pet?.apply(stored)
        }

        if let pet {
            if !pet.isVisible { pet.show() }
        } else {
            showPet()
        }
    }

    // MARK: - 动态宠物选择器

    private func openPetPicker() {
        if let w = petPickerWindow {
            (w.contentViewController as? PetPickerViewController)?.prepareForPresentation()
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let vc = PetPickerViewController()
        vc.onSelected = { [weak self] in self?.showPet() }

        let window = NSWindow(contentViewController: vc)
        vc.prepareForPresentation()
        window.title = "CodexPets"
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        petPickerWindow = window
    }
}
