import AppKit

/// 菜单栏常驻 + 全部调参入口（PRD R-07/R-08/R-09/R-10/R-11）。
/// 关掉宠物窗口 App 仍在托盘存活，这是「常驻」的定义。
final class TrayController {

    private let statusItem: NSStatusItem
    private var config: PetConfig { PetStore.shared.config }

    var onToggleVisibility: (() -> Void)?
    var onRecoverInteraction: (() -> Void)?
    var onConfigChanged: ((PetConfig) -> Void)?
    var onSelectPet: (() -> Void)?
    var isPetVisible: () -> Bool = { false }

    private lazy var scaleSlider = makeSlider(min: 0.2, max: 1.5, action: #selector(scaleChanged))
    private lazy var opacitySlider = makeSlider(min: 0.2, max: 1.0, action: #selector(opacityChanged))
    private var recoveryMenuItem: NSMenuItem?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "pawprint.fill",
                                   accessibilityDescription: "CodexPets")
            button.image?.isTemplate = true
        }
        statusItem.menu = buildMenu()
    }

    // MARK: - 菜单

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = MenuRefresher.shared
        MenuRefresher.shared.onWillOpen = { [weak self] in self?.syncControls() }

        let toggle = NSMenuItem(title: "显示 / 隐藏宠物",
                                action: #selector(toggleVisibility),
                                keyEquivalent: "p")
        toggle.keyEquivalentModifierMask = [.command, .option]
        toggle.target = self
        menu.addItem(toggle)

        menu.addItem(.separator())
        menu.addItem(labeled("大小", control: scaleSlider))
        menu.addItem(labeled("透明度", control: opacitySlider))
        menu.addItem(.separator())

        menu.addItem(check("鼠标跟随", #selector(toggleFollow)))
        menu.addItem(check("点击穿透（不挡下层）", #selector(toggleClickThrough)))

        let recover = NSMenuItem(
            title: "恢复宠物点击",
            action: #selector(recoverInteraction),
            keyEquivalent: "p"
        )
        recover.keyEquivalentModifierMask = [.command, .option, .shift]
        recover.target = self
        recover.isHidden = true
        recoveryMenuItem = recover
        menu.addItem(recover)

        menu.addItem(check("呼吸待机动效", #selector(toggleBreathing)))
        menu.addItem(check("开机自动启动", #selector(toggleLaunchAtLogin)))

        menu.addItem(.separator())
        let selectPet = NSMenuItem(
            title: "选择动态宠物…",
            action: #selector(selectPet),
            keyEquivalent: ""
        )
        selectPet.target = self
        menu.addItem(selectPet)

        let quit = NSMenuItem(title: "退出 CodexPets", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        return menu
    }

    private func check(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    private func labeled(_ title: String, control: NSView) -> NSMenuItem {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 32))
        let label = NSTextField(labelWithString: title)
        label.frame = NSRect(x: 14, y: 7, width: 60, height: 18)
        label.font = .menuFont(ofSize: 13)
        label.textColor = .secondaryLabelColor
        control.frame = NSRect(x: 78, y: 6, width: 148, height: 20)
        container.addSubview(label)
        container.addSubview(control)
        let item = NSMenuItem()
        item.view = container
        return item
    }

    private func makeSlider(min: Double, max: Double, action: Selector) -> NSSlider {
        let s = NSSlider(value: 1.0, minValue: min, maxValue: max, target: self, action: action)
        s.isContinuous = true
        return s
    }

    /// 菜单每次打开前把控件同步到当前配置
    private func syncControls() {
        scaleSlider.doubleValue = Double(config.scale)
        opacitySlider.doubleValue = Double(config.opacity)
        guard let menu = statusItem.menu else { return }
        menu.item(withTitle: "鼠标跟随")?.state = config.followMouse ? .on : .off
        menu.item(withTitle: "点击穿透（不挡下层）")?.state = config.clickThrough ? .on : .off
        recoveryMenuItem?.isHidden = !config.clickThrough
        menu.item(withTitle: "呼吸待机动效")?.state = config.breathingEnabled ? .on : .off
        menu.item(withTitle: "开机自动启动")?.state = LaunchAtLogin.isEnabled ? .on : .off
    }

    // MARK: - 动作

    private func mutate(_ change: (inout PetConfig) -> Void) {
        var c = PetStore.shared.config
        change(&c)
        let clamped = c.clamped()
        let stored = PetStore.shared.updateConfig(clamped)
        onConfigChanged?(stored)
    }

    /// 右键宠物时由 AppDelegate 调用：直接弹托盘菜单，不另做一套菜单
    func openMenu() {
        statusItem.button?.performClick(nil)
    }

    @objc private func toggleVisibility() { onToggleVisibility?() }
    @objc private func recoverInteraction() { onRecoverInteraction?() }
    @objc private func scaleChanged(_ s: NSSlider)   { mutate { $0.scale = CGFloat(s.doubleValue) } }
    @objc private func opacityChanged(_ s: NSSlider) { mutate { $0.opacity = CGFloat(s.doubleValue) } }
    @objc private func toggleFollow()        { mutate { $0.followMouse.toggle() } }
    @objc private func toggleClickThrough()  { mutate { $0.clickThrough.toggle() } }
    @objc private func toggleBreathing()     { mutate { $0.breathingEnabled.toggle() } }
    @objc private func selectPet()           { onSelectPet?() }

    @objc private func toggleLaunchAtLogin() {
        let target = !LaunchAtLogin.isEnabled
        let actual = LaunchAtLogin.set(target)
        mutate { $0.launchAtLogin = actual }
        if actual != target {
            let alert = NSAlert()
            alert.messageText = "没能设置开机自启"
            alert.informativeText = "请在「系统设置 → 通用 → 登录项与扩展」里手动允许 CodexPets。"
            alert.runModal()
        }
    }

    @objc private func quit() { NSApp.terminate(nil) }
}

/// NSMenuDelegate 单独拆出来，避免 TrayController 被 menu 强引用成环
final class MenuRefresher: NSObject, NSMenuDelegate {
    static let shared = MenuRefresher()
    var onWillOpen: (() -> Void)?
    func menuWillOpen(_ menu: NSMenu) { onWillOpen?() }
}
