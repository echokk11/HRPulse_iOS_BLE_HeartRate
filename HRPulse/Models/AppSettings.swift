import Foundation

/// 应用设置模型，用于持久化用户偏好
struct AppSettings: Codable {
    /// 是否启用后台运行模式
    var isBackgroundModeEnabled: Bool = true
    
    /// 是否已显示过首次启动引导
    var hasSeenOnboarding: Bool = false
    
    /// 用户年龄，用于计算目标心率区间
    var age: Int = 30
    
    /// 用户体重 (kg)
    var weightInKg: Double?
    
    /// 用户体脂率 (%)
    var bodyFatPercentage: Double?
    
    /// 用户偏好的颜色模式
    var colorScheme: AppColorScheme = .system
    
    // MARK: - Nested Types
    
    enum AppColorScheme: String, Codable, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
        
        var localizedName: String {
            switch self {
            case .system: return "跟随系统"
            case .light: return "浅色模式"
            case .dark: return "深色模式"
            }
        }
    }
    
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

    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case isBackgroundModeEnabled
        case hasSeenOnboarding
        case age
        case colorScheme
        case weightInKg
        case bodyFatPercentage
    }
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isBackgroundModeEnabled = try container.decodeIfPresent(Bool.self, forKey: .isBackgroundModeEnabled) ?? true
        hasSeenOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasSeenOnboarding) ?? false
        age = try container.decodeIfPresent(Int.self, forKey: .age) ?? 30
        colorScheme = try container.decodeIfPresent(AppColorScheme.self, forKey: .colorScheme) ?? .system
        weightInKg = try container.decodeIfPresent(Double.self, forKey: .weightInKg)
        bodyFatPercentage = try container.decodeIfPresent(Double.self, forKey: .bodyFatPercentage)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isBackgroundModeEnabled, forKey: .isBackgroundModeEnabled)
        try container.encode(hasSeenOnboarding, forKey: .hasSeenOnboarding)
        try container.encode(age, forKey: .age)
        try container.encode(colorScheme, forKey: .colorScheme)
        try container.encode(weightInKg, forKey: .weightInKg)
        try container.encode(bodyFatPercentage, forKey: .bodyFatPercentage)
    }
}
