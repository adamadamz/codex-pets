import AppKit
import ImageIO

struct PetPackageManifest: Codable, Equatable {
    let id: String
    let displayName: String
    let description: String?
    let spriteVersionNumber: Int?
    let spritesheetPath: String

    var resolvedSpriteVersionNumber: Int { spriteVersionNumber ?? 1 }
}

struct PetSpriteContract: Equatable {
    let version: Int
    let width: Int
    let height: Int
    let rows: Int
    let requiredFramesByRow: [Int]

    static let cellWidth = 192
    static let cellHeight = 208
    static let columns = 8

    static let v1 = PetSpriteContract(
        version: 1,
        width: 1536,
        height: 1872,
        rows: 9,
        requiredFramesByRow: [6, 8, 8, 4, 5, 8, 6, 6, 6]
    )

    static let v2 = PetSpriteContract(
        version: 2,
        width: 1536,
        height: 2288,
        rows: 11,
        requiredFramesByRow: [6, 8, 8, 4, 5, 8, 6, 6, 6, 8, 8]
    )

    static func contract(for version: Int) -> PetSpriteContract? {
        switch version {
        case 1: return .v1
        case 2: return .v2
        default: return nil
        }
    }
}

enum PetPackageError: LocalizedError, Equatable {
    case missingManifest
    case invalidManifest
    case unsupportedVersion(Int)
    case unsafeSpritesheetPath
    case missingSpritesheet
    case unreadableSpritesheet
    case invalidSpritesheetSize(expected: CGSize, actual: CGSize)
    case emptyRequiredFrame(row: Int, column: Int)

    var errorDescription: String? {
        switch self {
        case .missingManifest:
            return "这个目录里没有 pet.json。"
        case .invalidManifest:
            return "pet.json 缺少必要字段或格式不正确。"
        case let .unsupportedVersion(version):
            return "暂不支持 spriteVersionNumber = \(version)，请选择 Codex v1 或 v2 宠物。"
        case .unsafeSpritesheetPath:
            return "pet.json 的 spritesheetPath 不能指向宠物目录之外。"
        case .missingSpritesheet:
            return "找不到 pet.json 指定的 spritesheet.webp。"
        case .unreadableSpritesheet:
            return "spritesheet.webp 无法解码。"
        case let .invalidSpritesheetSize(expected, actual):
            return "图集尺寸是 \(Int(actual.width))×\(Int(actual.height))，应为 \(Int(expected.width))×\(Int(expected.height))。"
        case let .emptyRequiredFrame(row, column):
            return "图集第 \(row + 1) 行、第 \(column + 1) 格是空的，缺少必要动作帧。"
        }
    }
}

/// 已完成协议校验和逐格切片的 Codex 动态宠物。
struct DynamicPetAsset {
    let manifest: PetPackageManifest
    let packageURL: URL
    let spritesheetURL: URL
    let contract: PetSpriteContract
    private let frames: [[NSImage]]

    var idlePreview: NSImage { frame(row: 0, column: 0) }

    func frame(row: Int, column: Int) -> NSImage {
        guard frames.indices.contains(row), frames[row].indices.contains(column) else {
            return frames[0][0]
        }
        return frames[row][column]
    }

    static func load(from packageURL: URL) throws -> DynamicPetAsset {
        let root = packageURL.standardizedFileURL.resolvingSymlinksInPath()
        let manifestURL = root.appendingPathComponent("pet.json")
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw PetPackageError.missingManifest
        }
        guard let data = try? Data(contentsOf: manifestURL),
              let manifest = try? JSONDecoder().decode(PetPackageManifest.self, from: data),
              !manifest.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !manifest.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !manifest.spritesheetPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw PetPackageError.invalidManifest
        }

        let version = manifest.resolvedSpriteVersionNumber
        guard let contract = PetSpriteContract.contract(for: version) else {
            throw PetPackageError.unsupportedVersion(version)
        }

        let relativePath = manifest.spritesheetPath
        guard !relativePath.hasPrefix("/"),
              !relativePath.split(separator: "/").contains("..")
        else {
            throw PetPackageError.unsafeSpritesheetPath
        }
        let spritesheetURL = root.appendingPathComponent(relativePath)
            .standardizedFileURL
            .resolvingSymlinksInPath()
        let rootPrefix = root.path.hasSuffix("/") ? root.path : root.path + "/"
        guard spritesheetURL.path.hasPrefix(rootPrefix) else {
            throw PetPackageError.unsafeSpritesheetPath
        }
        guard FileManager.default.fileExists(atPath: spritesheetURL.path) else {
            throw PetPackageError.missingSpritesheet
        }
        guard let source = CGImageSourceCreateWithURL(spritesheetURL as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw PetPackageError.unreadableSpritesheet
        }

        let actualSize = CGSize(width: image.width, height: image.height)
        let expectedSize = CGSize(width: contract.width, height: contract.height)
        guard actualSize == expectedSize else {
            throw PetPackageError.invalidSpritesheetSize(
                expected: expectedSize,
                actual: actualSize
            )
        }

        var frames: [[NSImage]] = []
        frames.reserveCapacity(contract.rows)
        for row in 0..<contract.rows {
            var rowFrames: [NSImage] = []
            rowFrames.reserveCapacity(PetSpriteContract.columns)
            for column in 0..<PetSpriteContract.columns {
                let rect = CGRect(
                    x: column * PetSpriteContract.cellWidth,
                    y: row * PetSpriteContract.cellHeight,
                    width: PetSpriteContract.cellWidth,
                    height: PetSpriteContract.cellHeight
                )
                guard let cropped = image.cropping(to: rect) else {
                    throw PetPackageError.unreadableSpritesheet
                }
                if column < contract.requiredFramesByRow[row],
                   !Self.hasVisiblePixel(cropped) {
                    throw PetPackageError.emptyRequiredFrame(row: row, column: column)
                }
                rowFrames.append(
                    NSImage(
                        cgImage: cropped,
                        size: CGSize(
                            width: PetSpriteContract.cellWidth,
                            height: PetSpriteContract.cellHeight
                        )
                    )
                )
            }
            frames.append(rowFrames)
        }

        return DynamicPetAsset(
            manifest: manifest,
            packageURL: root,
            spritesheetURL: spritesheetURL,
            contract: contract,
            frames: frames
        )
    }

    private static func hasVisiblePixel(_ image: CGImage) -> Bool {
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return false }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return stride(from: 3, to: pixels.count, by: 4).contains {
            pixels[$0] > 0
        }
    }
}

struct PetSpriteFrame: Equatable {
    let row: Int
    let column: Int
    let durationMilliseconds: Double
}

enum PetAnimationState: Int, CaseIterable {
    case idle = 0
    case runningRight = 1
    case runningLeft = 2
    case waving = 3
    case jumping = 4
    case failed = 5
    case waiting = 6
    case running = 7
    case review = 8

    var frames: [PetSpriteFrame] {
        switch self {
        case .idle:
            let durations: [Double] = [280, 110, 110, 140, 140, 320]
            return durations.enumerated().map {
                PetSpriteFrame(row: rawValue, column: $0.offset,
                               durationMilliseconds: $0.element * 6)
            }
        case .runningRight, .runningLeft:
            return Self.uniform(row: rawValue, count: 8, duration: 120, last: 220)
        case .waving:
            return Self.uniform(row: rawValue, count: 4, duration: 140, last: 280)
        case .jumping:
            return Self.uniform(row: rawValue, count: 5, duration: 140, last: 280)
        case .failed:
            return Self.uniform(row: rawValue, count: 8, duration: 140, last: 240)
        case .waiting:
            return Self.uniform(row: rawValue, count: 6, duration: 150, last: 260)
        case .running:
            return Self.uniform(row: rawValue, count: 6, duration: 120, last: 220)
        case .review:
            return Self.uniform(row: rawValue, count: 6, duration: 150, last: 280)
        }
    }

    private static func uniform(
        row: Int,
        count: Int,
        duration: Double,
        last: Double
    ) -> [PetSpriteFrame] {
        (0..<count).map {
            PetSpriteFrame(
                row: row,
                column: $0,
                durationMilliseconds: $0 == count - 1 ? last : duration
            )
        }
    }
}

enum PetLookDirection {
    static func frame(
        petFrame: CGRect,
        pointer: CGPoint,
        spriteVersionNumber: Int
    ) -> PetSpriteFrame? {
        guard spriteVersionNumber == 2 else { return nil }
        let dx = pointer.x - petFrame.midX
        let dy = pointer.y - petFrame.midY
        guard hypot(dx, dy) > 1 else { return nil }

        // macOS 屏幕坐标 y 向上：atan2(dx, dy) 令正上方为 0°、右方为 90°。
        let degrees = (atan2(dx, dy) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
        let directionIndex = Int((degrees / 22.5).rounded()) % 16
        return PetSpriteFrame(
            row: 9 + directionIndex / 8,
            column: directionIndex % 8,
            durationMilliseconds: 0
        )
    }
}
