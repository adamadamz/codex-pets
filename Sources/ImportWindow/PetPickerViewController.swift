import AppKit

/// 动态宠物选择器。这里只接受 Codex pet.json + spritesheet.webp 包，
/// 普通照片不会再被伪装成宠物。
final class PetPickerViewController: NSViewController {

    var onSelected: (() -> Void)?

    private let titleLabel = NSTextField(labelWithString: "选择一只动态宠物")
    private let subtitleLabel = NSTextField(labelWithString:
        "真正的 Codex 宠物包含待机、奔跑、挥手、跳跃等多组动作；v2 还会朝光标方向看。")
    private let petPopup = NSPopUpButton()
    private let previewImageView = NSImageView()
    private let nameLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "")
    private let legacyHintLabel = NSTextField(labelWithString: "")
    private let chooseButton = NSButton(title: "让它来到桌面", target: nil, action: nil)
    private let importButton = NSButton(title: "导入宠物包…", target: nil, action: nil)
    private var assets: [DynamicPetAsset] = []

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 430))
        buildUI()
    }

    func prepareForPresentation() {
        loadViewIfNeeded()
        assets = PetStore.shared.availablePetAssets()
        petPopup.removeAllItems()
        for (index, asset) in assets.enumerated() {
            petPopup.addItem(withTitle: asset.manifest.displayName)
            petPopup.lastItem?.tag = index
        }

        if let selectedID = PetStore.shared.config.selectedPetID,
           let index = assets.firstIndex(where: { $0.manifest.id == selectedID }) {
            petPopup.selectItem(at: index)
        } else if !assets.isEmpty {
            petPopup.selectItem(at: 0)
        }

        petPopup.isEnabled = !assets.isEmpty
        chooseButton.isEnabled = !assets.isEmpty
        legacyHintLabel.stringValue = PetStore.shared.hasLegacyPhoto
            ? "旧版静态照片仍保留在本机，但不会再作为动态宠物显示。"
            : ""
        updatePreview()
    }

    private func buildUI() {
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)

        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.maximumNumberOfLines = 3
        subtitleLabel.preferredMaxLayoutWidth = 440

        petPopup.target = self
        petPopup.action = #selector(selectionChanged)

        previewImageView.imageScaling = .scaleProportionallyUpOrDown
        previewImageView.wantsLayer = true
        previewImageView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        previewImageView.layer?.cornerRadius = 16

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.alignment = .center
        detailLabel.font = .systemFont(ofSize: 11)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.alignment = .center

        legacyHintLabel.font = .systemFont(ofSize: 11)
        legacyHintLabel.textColor = .systemOrange
        legacyHintLabel.lineBreakMode = .byWordWrapping
        legacyHintLabel.maximumNumberOfLines = 2

        chooseButton.target = self
        chooseButton.action = #selector(chooseCurrentPet)
        chooseButton.keyEquivalent = "\r"

        importButton.target = self
        importButton.action = #selector(importPackage)

        let actions = NSStackView(views: [importButton, chooseButton])
        actions.orientation = .horizontal
        actions.spacing = 10

        let stack = NSStackView(views: [
            titleLabel,
            subtitleLabel,
            petPopup,
            previewImageView,
            nameLabel,
            detailLabel,
            legacyHintLabel,
            actions,
        ])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 40, bottom: 24, right: 40)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            subtitleLabel.widthAnchor.constraint(equalToConstant: 440),
            petPopup.widthAnchor.constraint(equalToConstant: 280),
            previewImageView.widthAnchor.constraint(equalToConstant: 154),
            previewImageView.heightAnchor.constraint(equalToConstant: 166),
            legacyHintLabel.widthAnchor.constraint(equalToConstant: 440),
        ])
    }

    @objc private func selectionChanged() {
        updatePreview()
    }

    private func updatePreview() {
        guard let asset = selectedAsset else {
            previewImageView.image = nil
            nameLabel.stringValue = "没有发现动态宠物"
            detailLabel.stringValue = "请导入包含 pet.json 与 spritesheet.webp 的目录"
            return
        }
        previewImageView.image = asset.idlePreview
        nameLabel.stringValue = asset.manifest.displayName
        let directionText = asset.contract.version == 2 ? " · 16 向注视" : ""
        detailLabel.stringValue = "Codex v\(asset.contract.version) · 9 组动作\(directionText)"
    }

    private var selectedAsset: DynamicPetAsset? {
        let index = petPopup.indexOfSelectedItem
        guard assets.indices.contains(index) else { return nil }
        return assets[index]
    }

    @objc private func chooseCurrentPet() {
        guard let asset = selectedAsset else { return }
        install(asset.packageURL)
    }

    @objc private func importPackage() {
        let panel = NSOpenPanel()
        panel.prompt = "导入动态宠物"
        panel.message = "选择包含 pet.json 和 spritesheet.webp 的宠物目录"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            install(url)
        }
    }

    private func install(_ packageURL: URL) {
        do {
            _ = try PetStore.shared.installPetPackage(from: packageURL)
            onSelected?()
            view.window?.close()
        } catch {
            let alert = NSAlert()
            alert.messageText = "这不是有效的动态宠物包"
            alert.informativeText = (error as? LocalizedError)?.errorDescription
                ?? error.localizedDescription
            alert.addButton(withTitle: "好")
            alert.runModal()
        }
    }
}
