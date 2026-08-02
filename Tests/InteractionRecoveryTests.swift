import Carbon.HIToolbox
import XCTest
@testable import CodexPets

final class InteractionRecoveryTests: XCTestCase {

    func testRecoveryDisablesClickThroughWithoutChangingOtherConfig() {
        var config = PetConfig()
        config.scale = 0.75
        config.opacity = 0.6
        config.followMouse = false
        config.clickThrough = true

        let recovered = PetInteractionRecovery.recoveredConfig(from: config)

        XCTAssertFalse(recovered.clickThrough)
        var expected = config
        expected.clickThrough = false
        XCTAssertEqual(recovered, expected)
    }

    func testRecoveryIsIdempotent() {
        let config = PetConfig()

        XCTAssertEqual(
            PetInteractionRecovery.recoveredConfig(from: config),
            config
        )
    }

    func testDefaultHotKeysKeepToggleAndAddShiftedRecovery() throws {
        let toggle = try XCTUnwrap(
            HotKeyBinding.defaults.first { $0.action == .toggleVisibility }
        )
        let recovery = try XCTUnwrap(
            HotKeyBinding.defaults.first { $0.action == .recoverInteraction }
        )

        XCTAssertEqual(toggle.keyCode, UInt32(kVK_ANSI_P))
        XCTAssertEqual(recovery.keyCode, UInt32(kVK_ANSI_P))
        XCTAssertEqual(toggle.modifiers & UInt32(shiftKey), 0)
        XCTAssertNotEqual(recovery.modifiers & UInt32(shiftKey), 0)
        XCTAssertNotEqual(toggle.modifiers, recovery.modifiers)
        XCTAssertEqual(Set(HotKeyBinding.defaults.map(\.action.rawValue)).count, 2)
    }

    func testCarbonRegistersAndUnregistersBothDefaultHotKeys() {
        let center = HotKeyCenter.shared
        center.unregister()
        addTeardownBlock { center.unregister() }

        center.register()

        XCTAssertEqual(center.registeredActions, Set(HotKeyAction.allCases))

        center.unregister()
        XCTAssertTrue(center.registeredActions.isEmpty)
    }
}
