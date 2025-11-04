import Foundation

/// 应用设置模型，用于持久化用户偏好
struct AppSettings: Codable {
    /// 是否启用后台运行模式
    var isBackgroundModeEnabled: Bool = true
    
    /// 是否已显示过首次启动引导
    var hasSeenOnboarding: Bool = false
    
    // MARK: - UserDefaults Key
    
    private static let userDefaultsKey = "HRPulse.AppSettings"
    
    // MARK: - Persistence Methods
    
    /// 从 UserDefaults 加载设置
    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            // 返回默认设置
            return AppSettings()
        }
        return settings
    }
    
    /// 保存设置到 UserDefaults
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: AppSettings.userDefaultsKey)
        }
    }
}
