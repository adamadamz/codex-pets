import CoreGraphics
import XCTest
@testable import CodexPets

final class PetScreenGeometryTests: XCTestCase {

    private let left = CGRect(x: -1440, y: 0, width: 1440, height: 900)
    private let main = CGRect(x: 0, y: 0, width: 1920, height: 1080)

    func testUsesScreenContainingPetCenter() {
        let index = PetScreenGeometry.bestScreenIndex(
            for: CGPoint(x: -700, y: 400),
            petSize: CGSize(width: 260, height: 260),
            screenFrames: [main, left]
        )

        XCTAssertEqual(index, 1)
    }

    func testUsesLargestPetIntersectionWhenCenterIsOutsideScreens() {
        let upper = CGRect(x: 0, y: 1100, width: 1920, height: 1080)
        let index = PetScreenGeometry.bestScreenIndex(
            for: CGPoint(x: 1000, y: 1095),
            petSize: CGSize(width: 300, height: 100),
            screenFrames: [main, upper]
        )

        XCTAssertEqual(index, 1)
    }

    func testUsesNearestScreenWhenPetDoesNotIntersectAnyScreen() {
        let index = PetScreenGeometry.bestScreenIndex(
            for: CGPoint(x: -1700, y: 450),
            petSize: CGSize(width: 100, height: 100),
            screenFrames: [main, left]
        )

        XCTAssertEqual(index, 1)
    }

    func testReturnsNilWithoutScreens() {
        XCTAssertNil(
            PetScreenGeometry.bestScreenIndex(
                for: .zero,
                petSize: CGSize(width: 100, height: 100),
                screenFrames: []
            )
        )
    }
}
