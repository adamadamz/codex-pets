import CoreGraphics
import XCTest
@testable import CodexPets

final class PetConfigTests: XCTestCase {

    func testClampedConstrainsEveryBoundedValue() {
        var config = PetConfig()
        config.scale = 9
        config.opacity = 0
        config.followSpeed = 1
        config.followRadius = 1
        config.followStopDistance = 999
        config.clickShakeAmount = -1
        config.clickScalePeak = 9
        config.edgeBounceDamping = -1
        config.breathingAmplitude = 1
        config.breathingPeriod = 99
        config.activeFPS = 1
        config.idleFPS = 99
        config.idleThreshold = 0

        let clamped = config.clamped()

        XCTAssertEqual(clamped.scale, 1.5)
        XCTAssertEqual(clamped.opacity, 0.2)
        XCTAssertEqual(clamped.followSpeed, 0.06)
        XCTAssertEqual(clamped.followRadius, 120)
        XCTAssertEqual(clamped.followStopDistance, 200)
        XCTAssertEqual(clamped.clickShakeAmount, 0)
        XCTAssertEqual(clamped.clickScalePeak, 1.4)
        XCTAssertEqual(clamped.edgeBounceDamping, 0)
        XCTAssertEqual(clamped.breathingAmplitude, 0.1)
        XCTAssertEqual(clamped.breathingPeriod, 12)
        XCTAssertEqual(clamped.activeFPS, 15)
        XCTAssertEqual(clamped.idleFPS, 30)
        XCTAssertEqual(clamped.idleThreshold, 0.5)
    }

    func testRenderSizePreservesAspectRatioAndUsesScale() {
        var config = PetConfig()
        config.intrinsicSize = CGSize(width: 1000, height: 500)
        config.scale = 1

        XCTAssertEqual(config.renderSize, CGSize(width: 260, height: 130))

        config.scale = 0.5
        XCTAssertEqual(config.renderSize, CGSize(width: 130, height: 65))
    }

    func testRenderSizeFallsBackForInvalidIntrinsicSize() {
        var config = PetConfig()
        config.intrinsicSize = .zero

        XCTAssertEqual(config.renderSize, CGSize(width: 200, height: 200))
    }

    func testLegacyConfigWithoutSelectedPetIDStillDecodes() throws {
        let encoded = try JSONEncoder().encode(PetConfig())
        var json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        json.removeValue(forKey: "selectedPetID")

        let legacyData = try JSONSerialization.data(withJSONObject: json)
        let decoded = try JSONDecoder().decode(PetConfig.self, from: legacyData)

        XCTAssertNil(decoded.selectedPetID)
    }
}
