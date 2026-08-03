import Foundation
import ServiceManagement

/// 开机自启（macOS 13+ 的 SMAppService.mainApp）。
/// 该 API 会把控制权交给系统“登录项”设置，兼容沙盒且不需要额外 Helper。
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
