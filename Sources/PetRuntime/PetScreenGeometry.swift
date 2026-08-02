import CoreGraphics

/// 多显示器选择的纯几何规则。返回 screenFrames 中最适合约束当前宠物的索引。
enum PetScreenGeometry {

    static func bestScreenIndex(
        for center: CGPoint,
        petSize: CGSize,
        screenFrames: [CGRect]
    ) -> Int? {
        guard !screenFrames.isEmpty else { return nil }

        if let containing = screenFrames.firstIndex(where: { contains(center, in: $0) }) {
            return containing
        }

        let petFrame = CGRect(
            x: center.x - petSize.width / 2,
            y: center.y - petSize.height / 2,
            width: petSize.width,
            height: petSize.height
        )

        var bestOverlapIndex: Int?
        var bestOverlapArea: CGFloat = 0

        for (index, screenFrame) in screenFrames.enumerated() {
            let intersection = petFrame.intersection(screenFrame)
            let area = intersection.isNull || intersection.isEmpty
                ? 0
                : intersection.width * intersection.height
            if area > bestOverlapArea {
                bestOverlapArea = area
                bestOverlapIndex = index
            }
        }

        if let bestOverlapIndex {
            return bestOverlapIndex
        }

        return screenFrames.indices.min {
            squaredDistance(from: center, to: screenFrames[$0])
                < squaredDistance(from: center, to: screenFrames[$1])
        }
    }

    private static func contains(_ point: CGPoint, in rect: CGRect) -> Bool {
        point.x >= rect.minX && point.x <= rect.maxX
            && point.y >= rect.minY && point.y <= rect.maxY
    }

    private static func squaredDistance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let dx = max(max(rect.minX - point.x, 0), point.x - rect.maxX)
        let dy = max(max(rect.minY - point.y, 0), point.y - rect.maxY)
        return dx * dx + dy * dy
    }
}
