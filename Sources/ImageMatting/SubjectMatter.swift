import AppKit
import CoreImage
import Vision

/// 抠图结果
struct MattingResult {
    let image: CGImage          // 带 alpha 的角色图
    let subjectBounds: CGRect   // 在 image 坐标系（左上原点）下的主体包围盒
    let confidence: Double      // 0–1，<0.5 视为不可靠
    let usedFallback: Bool      // true = 未抠图，直接用原图
    let warning: String?
}

enum MattingError: LocalizedError {
    case cannotDecode
    case noSubject

    var errorDescription: String? {
        switch self {
        case .cannotDecode: return "无法读取这张图片，换一张试试。"
        case .noSubject:    return "没能在图里认出主体，可以选「不抠图直接用」。"
        }
    }
}

/// 纯本地主体抠图。
/// 依赖 macOS 14+ 的 VNGenerateForegroundInstanceMaskRequest —— 与系统「拷贝主体」同一套能力。
/// 全程不联网、不落临时文件。
enum SubjectMatter {

    static func extract(from source: CGImage) throws -> MattingResult {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: source, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return fallback(source, warning: "抠图失败，已使用整图。")
        }

        guard let observation = request.results?.first,
              !observation.allInstances.isEmpty else {
            throw MattingError.noSubject
        }

        do {
            let buffer = try observation.generateMaskedImage(
                ofInstances: observation.allInstances,
                from: handler,
                croppedToInstancesExtent: false
            )
            let ci = CIImage(cvPixelBuffer: buffer)
            let ctx = CIContext(options: [.useSoftwareRenderer: false])
            guard let cut = ctx.createCGImage(ci, from: ci.extent) else {
                return fallback(source, warning: "抠图渲染失败，已使用整图。")
            }

            let bounds = alphaBounds(of: cut) ?? CGRect(origin: .zero,
                                                       size: CGSize(width: cut.width, height: cut.height))
            // 置信度启发式：主体占比过小或几乎占满 → 抠图很可能不可靠
            let ratio = (bounds.width * bounds.height) /
                        CGFloat(max(cut.width * cut.height, 1))
            let confidence: Double = (ratio < 0.02 || ratio > 0.985) ? 0.4 : 0.9

            return MattingResult(
                image: cut,
                subjectBounds: bounds,
                confidence: confidence,
                usedFallback: false,
                warning: confidence < 0.5 ? "主体识别把握不大，必要时手动擦一擦。" : nil
            )
        } catch {
            return fallback(source, warning: "抠图失败，已使用整图。")
        }
    }

    /// 已带透明通道的 PNG 走这条路：不动像素，只算包围盒
    static func passthrough(_ source: CGImage) -> MattingResult {
        let bounds = alphaBounds(of: source) ?? CGRect(origin: .zero,
                                                      size: CGSize(width: source.width, height: source.height))
        return MattingResult(image: source, subjectBounds: bounds,
                             confidence: 0.95, usedFallback: false, warning: nil)
    }

    static func fallback(_ source: CGImage, warning: String?) -> MattingResult {
        MattingResult(
            image: source,
            subjectBounds: CGRect(x: 0, y: 0, width: source.width, height: source.height),
            confidence: 0.3,
            usedFallback: true,
            warning: warning
        )
    }

    // MARK: - 包围盒

    /// 扫描 alpha 通道求最小非透明矩形。返回左上原点坐标系。
    /// 为控制耗时，按步长采样（大图步长更大）。
    static func alphaBounds(of image: CGImage, alphaThreshold: UInt8 = 8) -> CGRect? {
        let w = image.width, h = image.height
        guard w > 0, h > 0 else { return nil }

        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        guard let ctx = CGContext(
            data: &pixels, width: w, height: h,
            bitsPerComponent: 8, bytesPerRow: w * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))

        let step = max(1, Int((Double(max(w, h)) / 512.0).rounded(.down)))
        var minX = w, minY = h, maxX = -1, maxY = -1

        for y in stride(from: 0, to: h, by: step) {
            let row = y * w * 4
            for x in stride(from: 0, to: w, by: step) {
                if pixels[row + x * 4 + 3] > alphaThreshold {
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                }
            }
        }
        guard maxX >= minX, maxY >= minY else { return nil }

        // 采样点只证明这个步长区间内存在主体；向外扩一格，避免低估真实边缘。
        minX = max(0, minX - step + 1)
        minY = max(0, minY - step + 1)
        maxX = min(w - 1, maxX + step - 1)
        maxY = min(h - 1, maxY + step - 1)

        // CGContext 绘制为左下原点；换算成左上原点
        let topY = h - 1 - maxY
        return CGRect(x: CGFloat(minX), y: CGFloat(topY),
                      width: CGFloat(maxX - minX + 1),
                      height: CGFloat(maxY - minY + 1))
    }
}
