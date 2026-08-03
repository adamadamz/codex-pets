import XCTest
@testable import CodexPets

final class PetStoreDiscoveryTests: XCTestCase {

    func testAppStoreDiscoveryOnlyUsesSandboxPackages() {
        let appPackages = URL(fileURLWithPath: "/sandbox/pets", isDirectory: true)
        let home = URL(fileURLWithPath: "/Users/tester", isDirectory: true)

        XCTAssertEqual(
            PetStore.discoveryRoots(
                appPackagesURL: appPackages,
                homeDirectory: home,
                includeCodexDirectory: false
            ),
            [appPackages]
        )
    }

    func testDirectBuildCanAlsoDiscoverCodexPackages() {
        let appPackages = URL(fileURLWithPath: "/sandbox/pets", isDirectory: true)
        let home = URL(fileURLWithPath: "/Users/tester", isDirectory: true)

        XCTAssertEqual(
            PetStore.discoveryRoots(
                appPackagesURL: appPackages,
                homeDirectory: home,
                includeCodexDirectory: true
            ),
            [
                home.appendingPathComponent(".codex/pets", isDirectory: true),
                appPackages,
            ]
        )
    }
}
