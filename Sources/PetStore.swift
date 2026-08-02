import AppKit

/// 配置与资源的本地持久化。全部落在 ~/Library/Application Support/CodexPets/。
/// 不联网、不上传、不做任何统计。
final class PetStore {

    static let shared = PetStore()
    private init() { config = PetStore.loadConfig() }

    private let configFileName = "config.json"
    private let legacyAssetFileName = "pet.png"
    private let petPackagesDirectoryName = "pets"

    private(set) var config: PetConfig

    // MARK: - 配置

    private static func loadConfig() -> PetConfig {
        guard let dir = try? ImageOptimizer.appSupportDirectory(),
              let data = try? Data(contentsOf: dir.appendingPathComponent("config.json")),
              let c = try? JSONDecoder().decode(PetConfig.self, from: data)
        else { return PetConfig() }
        return c.clamped()
    }

    @discardableResult
    func updateConfig(_ newConfig: PetConfig) -> PetConfig {
        let safeConfig = newConfig.clamped()
        do {
            try writeConfig(safeConfig)
            config = safeConfig
        } catch {
            NSLog("[CodexPets] 配置保存失败: \(error.localizedDescription)")
        }
        return config
    }

    private func writeConfig(_ config: PetConfig) throws {
        let dir = try ImageOptimizer.appSupportDirectory()
        let data = try JSONEncoder().encode(config)
        try data.write(to: dir.appendingPathComponent(configFileName), options: .atomic)
    }

    // MARK: - 资源

    var hasPet: Bool { loadPetAsset() != nil }

    var hasLegacyPhoto: Bool {
        ImageOptimizer.readPNG(fileName: legacyAssetFileName) != nil
    }

    func loadPetAsset() -> DynamicPetAsset? {
        guard let selectedPetID = config.selectedPetID,
              let packageURL = try? installedPetPackageURL(for: selectedPetID)
        else { return nil }
        return try? DynamicPetAsset.load(from: packageURL)
    }

    /// 同时发现 App 已保存的包与 Codex 自定义宠物目录。失败包会被忽略，
    /// 选择时仍会再次完整校验，避免把一张普通图片当成宠物。
    func availablePetAssets() -> [DynamicPetAsset] {
        var assetsByID: [String: DynamicPetAsset] = [:]
        let home = FileManager.default.homeDirectoryForCurrentUser
        let codexPets = home.appendingPathComponent(".codex/pets", isDirectory: true)
        let appPets = (try? petPackagesDirectory())

        for root in [codexPets, appPets].compactMap({ $0 }) {
            guard let children = try? FileManager.default.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }
            for child in children {
                guard (try? child.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true,
                      let asset = try? DynamicPetAsset.load(from: child)
                else { continue }
                assetsByID[asset.manifest.id] = asset
            }
        }

        return assetsByID.values.sorted {
            $0.manifest.displayName.localizedStandardCompare($1.manifest.displayName)
                == .orderedAscending
        }
    }

    /// 校验后把动态宠物复制进 App Support，再切换 selectedPetID。
    /// 源目录与旧版 pet.png 都不会被修改。
    @discardableResult
    func installPetPackage(from sourceURL: URL) throws -> DynamicPetAsset {
        let source = try DynamicPetAsset.load(from: sourceURL)
        let safeID = Self.safePackageID(source.manifest.id)
        guard !safeID.isEmpty else { throw PetPackageError.invalidManifest }

        let packages = try petPackagesDirectory()
        let destination = packages.appendingPathComponent(safeID, isDirectory: true)
        let staging = packages.appendingPathComponent(
            ".\(safeID)-staging-\(UUID().uuidString)",
            isDirectory: true
        )
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)

        do {
            try fileManager.copyItem(
                at: source.spritesheetURL,
                to: staging.appendingPathComponent("spritesheet.webp")
            )
            let storedManifest = PetPackageManifest(
                id: safeID,
                displayName: source.manifest.displayName,
                description: source.manifest.description,
                spriteVersionNumber: source.contract.version,
                spritesheetPath: "spritesheet.webp"
            )
            let manifestData = try JSONEncoder().encode(storedManifest)
            try manifestData.write(
                to: staging.appendingPathComponent("pet.json"),
                options: .atomic
            )

            _ = try DynamicPetAsset.load(from: staging)
            if fileManager.fileExists(atPath: destination.path) {
                _ = try fileManager.replaceItemAt(destination, withItemAt: staging)
            } else {
                try fileManager.moveItem(at: staging, to: destination)
            }
        } catch {
            try? fileManager.removeItem(at: staging)
            throw error
        }

        let installed = try DynamicPetAsset.load(from: destination)
        var newConfig = config
        newConfig.selectedPetID = safeID
        newConfig.assetFileName = "spritesheet.webp"
        newConfig.intrinsicSize = CGSize(
            width: PetSpriteContract.cellWidth,
            height: PetSpriteContract.cellHeight
        )
        newConfig.subjectBounds = CGRect(origin: .zero, size: newConfig.intrinsicSize)
        newConfig.headHotZone = CGRect(
            x: 0,
            y: 0,
            width: newConfig.intrinsicSize.width,
            height: (newConfig.intrinsicSize.height / 3).rounded()
        )
        let storedConfig = updateConfig(newConfig)
        guard storedConfig.selectedPetID == safeID else {
            throw CocoaError(.fileWriteUnknown)
        }
        return installed
    }

    private func petPackagesDirectory() throws -> URL {
        let base = try ImageOptimizer.appSupportDirectory()
        let directory = base.appendingPathComponent(petPackagesDirectoryName, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        return directory
    }

    private func installedPetPackageURL(for id: String) throws -> URL {
        try petPackagesDirectory().appendingPathComponent(Self.safePackageID(id), isDirectory: true)
    }

    private static func safePackageID(_ id: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return id.unicodeScalars.map { allowed.contains($0) ? Character(String($0)) : "-" }
            .reduce(into: "") { $0.append($1) }
    }

}
