import AppKit
import ImageIO
import UniformTypeIdentifiers

/// 图片轻量化：长边压到 ≤1024，重编码 PNG（保留 alpha）。
/// 目标：单个宠物资源包 ≤2MB（PRD F-05）。
enum ImageOptimizer {

    static let maxLongSide: CGFloat = 1024
    static let maxInputLongSide: CGFloat = 2048

    /// `.noneSkipFirst` / `.noneSkipLast` 只是内存布局占位，不代表图片真的透明。
    static func hasUsableAlpha(_ alphaInfo: CGImageAlphaInfo) -> Bool {
        switch alphaInfo {
        case .premultipliedFirst, .premultipliedLast, .first, .last, .alphaOnly:
            return true
        case .none, .noneSkipFirst, .noneSkipLast:
            return false
        @unknown default:
            return false
        }
    }

    /// 从文件读取并降采样。超过 2048 的图先降到 2048 再进抠图，避免 Vision 耗时飙升。
    static func loadForMatting(url: URL) throws -> (image: CGImage, hasAlpha: Bool) {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw MattingError.cannotDecode
        }
        let opts: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: maxInputLongSide,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let img = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else {
            throw MattingError.cannotDecode
        }
        let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any]
        let hasAlpha = (props?[kCGImagePropertyHasAlpha] as? Bool)
            ?? hasUsableAlpha(img.alphaInfo)
        return (img, hasAlpha)
    }

    /// 等比降采样到 maxLongSide
    static func downsample(_ image: CGImage, longSide: CGFloat = maxLongSide) -> CGImage {
        let w = CGFloat(image.width), h = CGFloat(image.height)
        let current = max(w, h)
        guard current > longSide else { return image }

        let f = longSide / current
        let nw = Int((w * f).rounded()), nh = Int((h * f).rounded())
        guard let ctx = CGContext(
            data: nil, width: nw, height: nh,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return image }
        ctx.interpolationQuality = .high
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: nw, height: nh))
        return ctx.makeImage() ?? image
    }

    /// 先写临时文件，再替换正式 PNG，避免进程中断留下半个文件。
    @discardableResult
    static func writePNG(_ image: CGImage, fileName: String) throws -> URL {
        let dir = try appSupportDirectory()
        let url = dir.appendingPathComponent(fileName)
        let temporaryURL = dir.appendingPathComponent(".\(UUID().uuidString)-\(fileName)")
        let fileManager = FileManager.default

        defer {
            if fileManager.fileExists(atPath: temporaryURL.path) {
                try? fileManager.removeItem(at: temporaryURL)
            }
        }

        guard let dest = CGImageDestinationCreateWithURL(
            temporaryURL as CFURL, UTType.png.identifier as CFString, 1, nil
        ) else { throw MattingError.cannotDecode }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else { throw MattingError.cannotDecode }

        if fileManager.fileExists(atPath: url.path) {
            _ = try fileManager.replaceItemAt(url, withItemAt: temporaryURL)
        } else {
            try fileManager.moveItem(at: temporaryURL, to: url)
        }
        return url
    }

    static func readPNG(fileName: String) -> CGImage? {
        guard let dir = try? appSupportDirectory() else { return nil }
        let url = dir.appendingPathComponent(fileName)
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(src, 0, nil)
    }

    static func appSupportDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        )
        let dir = base.appendingPathComponent("CodexPets", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
