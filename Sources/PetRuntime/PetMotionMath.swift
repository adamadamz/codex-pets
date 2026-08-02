import CoreGraphics

/// 与 Timer、AppKit 输入无关的运动数学。统一以 60fps 作为参数语义基准，
/// 让 activeFPS 改为 15 / 30 / 60 时保持相同的跟随和惯性手感。
enum PetMotionMath {

    static let referenceFPS: Double = 60
    static let maximumSimulationDelta: Double = 0.1

    static func simulationDelta(from rawDelta: Double) -> Double {
        min(max(rawDelta, 0), maximumSimulationDelta)
    }

    static func referenceFrames(for deltaTime: Double) -> Double {
        max(deltaTime, 0) * referenceFPS
    }

    /// 把“每个 60fps 基准帧接近剩余距离的比例”换算成本次实际 dt 的比例。
    static func approachFraction(perReferenceFrame: CGFloat, deltaTime: Double) -> CGFloat {
        let fraction = min(max(perReferenceFrame, 0), 1)
        guard fraction < 1 else { return 1 }
        let frames = referenceFrames(for: deltaTime)
        return 1 - CGFloat(pow(Double(1 - fraction), frames))
    }

    /// 返回惯性在本次 dt 内的位移倍率和剩余速度倍率。
    ///
    /// 位移倍率使用等比数列求和，因此一次 30fps 更新与两次 60fps 更新等价。
    static func inertiaFactors(
        dampingPerReferenceFrame damping: CGFloat,
        deltaTime: Double
    ) -> (travel: CGFloat, remainingVelocity: CGFloat) {
        let safeDamping = min(max(damping, 0), 1)
        let frames = referenceFrames(for: deltaTime)

        guard frames > 0 else { return (0, 1) }
        guard safeDamping < 1 else {
            return (CGFloat(frames), 1)
        }

        let remaining = CGFloat(pow(Double(safeDamping), frames))
        let travel = (1 - remaining) / (1 - safeDamping)
        return (travel, remaining)
    }
}
