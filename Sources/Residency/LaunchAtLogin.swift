import Foundation
import ServiceManagement

/// 开机自启（macOS 13+ 的 SMAppService）。
/// 注意：若日后上 Mac App Store 并开启沙盒，此能力需改用 Login Item Helper 并重新评估。
enum LaunchAtLogin {

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// 返回操作后的真实状态（用户可能在系统设置里拒绝过）
    @discardableResult
    static func set(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            NSLog("[CodexPets] 开机自启设置失败: \(error.localizedDescription)")
        }
        return isEnabled
    }
}
