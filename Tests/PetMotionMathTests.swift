import CoreGraphics
import XCTest
@testable import CodexPets

final class PetMotionMathTests: XCTestCase {

    func testApproachFractionIsFrameRateIndependent() {
        let oneStepAt30 = PetMotionMath.approachFraction(
            perReferenceFrame: 0.02,
            deltaTime: 1.0 / 30.0
        )
        let oneStepAt60 = PetMotionMath.approachFraction(
            perReferenceFrame: 0.02,
            deltaTime: 1.0 / 60.0
        )
        let twoStepsAt60 = 1 - (1 - oneStepAt60) * (1 - oneStepAt60)

        XCTAssertEqual(oneStepAt30, twoStepsAt60, accuracy: 0.000_001)
    }

    func testInertiaAt30MatchesTwoReferenceFrames() {
        let oneStepAt30 = PetMotionMath.inertiaFactors(
            dampingPerReferenceFrame: 0.94,
            deltaTime: 1.0 / 30.0
        )
        let oneStepAt60 = PetMotionMath.inertiaFactors(
            dampingPerReferenceFrame: 0.94,
            deltaTime: 1.0 / 60.0
        )

        let twoStepTravel = oneStepAt60.travel
            + oneStepAt60.remainingVelocity * oneStepAt60.travel
        let twoStepVelocity = oneStepAt60.remainingVelocity
            * oneStepAt60.remainingVelocity

        XCTAssertEqual(oneStepAt30.travel, twoStepTravel, accuracy: 0.000_001)
        XCTAssertEqual(
            oneStepAt30.remainingVelocity,
            twoStepVelocity,
            accuracy: 0.000_001
        )
    }

    func testSimulationDeltaRejectsNegativeAndCapsLongStalls() {
        XCTAssertEqual(PetMotionMath.simulationDelta(from: -1), 0)
        XCTAssertEqual(
            PetMotionMath.simulationDelta(from: 2),
            PetMotionMath.maximumSimulationDelta
        )
    }
}
