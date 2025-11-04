import SwiftUI

/// 颜色主题，支持深色和浅色模式自动适配
struct ColorTheme {
    // MARK: - Heart Colors
    
    /// 心脏连接时的颜色（深色模式下调亮以确保可见性）
    static func heartConnected(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            // 深色模式下使用更亮的红色
            return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .light:
            // 浅色模式下使用标准红色
            return .red
        @unknown default:
            return .red
        }
    }
    
    /// 心脏断开连接时的颜色
    static let heartDisconnected = Color.gray.opacity(0.3)
    
    // MARK: - Pulse Colors
    
    /// 脉冲波纹颜色（深色模式下调亮）
    static func pulseColor(for colorScheme: ColorScheme) -> Color {
        switch colorScheme {
        case .dark:
            return Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.6)
        case .light:
            return Color.red.opacity(0.6)
        @unknown default:
            return Color.red.opacity(0.6)
        }
    }
    
    // MARK: - Text Colors
    
    /// BPM 数值文字颜色（自动适配）
    static let bpmText = Color.primary
    
    /// 次要文字颜色（自动适配）
    static let secondaryText = Color.secondary
    
    /// 断开连接时的文字颜色
    static let disconnectedText = Color.gray
    
    // MARK: - Background Colors
    
    /// 主背景颜色（自动适配）
    static let background = Color(UIColor.systemBackground)
    
    /// 次要背景颜色（自动适配）
    static let secondaryBackground = Color(UIColor.secondarySystemBackground)
}
