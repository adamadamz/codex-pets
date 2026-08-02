import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import CodexPets

final class PetSpriteTests: XCTestCase {

    func testCodexContractsUseExpectedAtlasGeometry() {
        XCTAssertEqual(PetSpriteContract.v1.width, 1536)
        XCTAssertEqual(PetSpriteContract.v1.height, 1872)
        XCTAssertEqual(PetSpriteContract.v1.rows, 9)
        XCTAssertEqual(PetSpriteContract.v2.width, 1536)
        XCTAssertEqual(PetSpriteContract.v2.height, 2288)
        XCTAssertEqual(PetSpriteContract.v2.rows, 11)
        XCTAssertEqual(PetSpriteContract.cellWidth, 192)
        XCTAssertEqual(PetSpriteContract.cellHeight, 208)
    }

    func testAllStandardAnimationRowsHaveCodexFrameCounts() {
        let counts = PetAnimationState.allCases.map { $0.frames.count }
        XCTAssertEqual(counts, [6, 8, 8, 4, 5, 8, 6, 6, 6])
        for state in PetAnimationState.allCases {
            XCTAssertTrue(state.frames.allSatisfy { $0.row == state.rawValue })
            XCTAssertEqual(state.frames.map(\.column), Array(0..<state.frames.count))
        }
    }

    func testV2LookDirectionMapsCardinalsInMacScreenCoordinates() throws {
        let pet = CGRect(x: 40, y: 40, width: 20, height: 20)

        XCTAssertEqual(
            try XCTUnwrap(PetLookDirection.frame(
                petFrame: pet,
                pointer: CGPoint(x: 50, y: 100),
                spriteVersionNumber: 2
            )),
            PetSpriteFrame(row: 9, column: 0, durationMilliseconds: 0)
        )
        XCTAssertEqual(
            try XCTUnwrap(PetLookDirection.frame(
                petFrame: pet,
                pointer: CGPoint(x: 100, y: 50),
                spriteVersionNumber: 2
            )),
            PetSpriteFrame(row: 9, column: 4, durationMilliseconds: 0)
        )
        XCTAssertEqual(
            try XCTUnwrap(PetLookDirection.frame(
                petFrame: pet,
                pointer: CGPoint(x: 50, y: 0),
                spriteVersionNumber: 2
            )),
            PetSpriteFrame(row: 10, column: 0, durationMilliseconds: 0)
        )
        XCTAssertEqual(
            try XCTUnwrap(PetLookDirection.frame(
                petFrame: pet,
                pointer: CGPoint(x: 0, y: 50),
                spriteVersionNumber: 2
            )),
            PetSpriteFrame(row: 10, column: 4, durationMilliseconds: 0)
        )
    }

    func testV1DoesNotUseLookDirectionRows() {
        XCTAssertNil(PetLookDirection.frame(
            petFrame: CGRect(x: 0, y: 0, width: 20, height: 20),
            pointer: CGPoint(x: 100, y: 100),
            spriteVersionNumber: 1
        ))
    }

    func testLoadRejectsTransparentRequiredFrame() throws {
        let packageURL = try makeTemporaryPackage(emptyRequiredFrame: (row: 0, column: 0))
        defer { try? FileManager.default.removeItem(at: packageURL) }

        XCTAssertThrowsError(try DynamicPetAsset.load(from: packageURL)) { error in
            XCTAssertEqual(error as? PetPackageError, .emptyRequiredFrame(row: 0, column: 0))
        }
    }

    func testLoadRejectsSpritesheetSymlinkOutsidePackage() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let packageURL = root.appendingPathComponent("pet", isDirectory: true)
        let outsideURL = root.appendingPathComponent("outside.webp")
        try FileManager.default.createDirectory(at: packageURL, withIntermediateDirectories: true)
        try Data().write(to: outsideURL)
        defer { try? FileManager.default.removeItem(at: root) }

        let manifest = PetPackageManifest(
            id: "symlink-test",
            displayName: "Symlink Test",
            description: nil,
            spriteVersionNumber: 1,
            spritesheetPath: "spritesheet.webp"
        )
        try JSONEncoder().encode(manifest).write(
            to: packageURL.appendingPathComponent("pet.json")
        )
        try FileManager.default.createSymbolicLink(
            at: packageURL.appendingPathComponent("spritesheet.webp"),
            withDestinationURL: outsideURL
        )

        XCTAssertThrowsError(try DynamicPetAsset.load(from: packageURL)) { error in
            XCTAssertEqual(error as? PetPackageError, .unsafeSpritesheetPath)
        }
    }

    private func makeTemporaryPackage(
        emptyRequiredFrame: (row: Int, column: Int)?
    ) throws -> URL {
        let packageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: packageURL, withIntermediateDirectories: true)

        let manifest = PetPackageManifest(
            id: "frame-test",
            displayName: "Frame Test",
            description: nil,
            spriteVersionNumber: 1,
            spritesheetPath: "spritesheet.webp"
        )
        try JSONEncoder().encode(manifest).write(
            to: packageURL.appendingPathComponent("pet.json")
        )

        let contract = PetSpriteContract.v1
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let context = try XCTUnwrap(CGContext(
            data: nil,
            width: contract.width,
            height: contract.height,
            bitsPerComponent: 8,
            bytesPerRow: contract.width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ))
        context.clear(CGRect(x: 0, y: 0, width: contract.width, height: contract.height))
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: contract.width, height: contract.height))
        if let emptyRequiredFrame {
            // CGImage cropping addresses rows from the encoded image's top edge, while CGContext
            // drawing coordinates start at the bottom edge.
            context.clear(CGRect(
                x: emptyRequiredFrame.column * PetSpriteContract.cellWidth,
                y: (contract.rows - 1 - emptyRequiredFrame.row) * PetSpriteContract.cellHeight,
                width: PetSpriteContract.cellWidth,
                height: PetSpriteContract.cellHeight
            ))
        }

        let image = try XCTUnwrap(context.makeImage())
        let spritesheetURL = packageURL.appendingPathComponent("spritesheet.webp")
        let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(
            spritesheetURL as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ))
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return packageURL
    }
}
