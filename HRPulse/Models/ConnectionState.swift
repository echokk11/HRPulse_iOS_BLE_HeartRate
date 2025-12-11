import Foundation

/// 蓝牙连接状态枚举
enum ConnectionState {
    case disconnected  // 断开连接
    case scanning      // 正在扫描设备
    case connecting    // 正在连接
    case connected     // 已连接
    
    /// 是否处于活跃连接状态
    var isConnected: Bool {
        return self == .connected
    }
    
    /// 是否正在尝试连接
    var isAttemptingConnection: Bool {
        return self == .scanning || self == .connecting
    }
}
