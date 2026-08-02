import CoreGraphics
import XCTest
@testable import CodexPets

final class ImageOptimizerTests: XCTestCase {

    func testOnlyRealAlphaLayoutsAreAccepted() {
        XCTAssertTrue(ImageOptimizer.hasUsableAlpha(.premultipliedFirst))
        XCTAssertTrue(ImageOptimizer.hasUsableAlpha(.premultipliedLast))
        XCTAssertTrue(ImageOptimizer.hasUsableAlpha(.first))
        XCTAssertTrue(ImageOptimizer.hasUsableAlpha(.last))
        XCTAssertTrue(ImageOptimizer.hasUsableAlpha(.alphaOnly))

        XCTAssertFalse(ImageOptimizer.hasUsableAlpha(.none))
        XCTAssertFalse(ImageOptimizer.hasUsableAlpha(.noneSkipFirst))
        XCTAssertFalse(ImageOptimizer.hasUsableAlpha(.noneSkipLast))
    }
}
