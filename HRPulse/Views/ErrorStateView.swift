import SwiftUI

/// 错误状态显示视图
struct ErrorStateView: View {
    let error: BluetoothError
    let onOpenSettings: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // 错误图标
            Image(systemName: iconName)
                .font(.system(size: 60))
                .foregroundColor(.red.opacity(0.8))
            
            // 错误标题
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // 错误描述
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 操作按钮
            VStack(spacing: 12) {
                if error.requiresUserAction {
                    Button(action: onOpenSettings) {
                        HStack {
                            Image(systemName: "gear")
                            Text("打开设置")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                
                Button(action: onDismiss) {
                    Text(error.requiresUserAction ? "稍后处理" : "确定")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(ColorTheme.background)
                .shadow(radius: 20)
        )
        .padding(40)
    }
    
    private var iconName: String {
        switch error {
        case .unauthorized:
            return "lock.shield"
        case .bluetoothOff:
            return "antenna.radiowaves.left.and.right.slash"
        case .unsupported:
            return "exclamationmark.triangle"
        default:
            return "exclamationmark.circle"
        }
    }
    
    private var title: String {
        switch error {
        case .unauthorized:
            return "需要蓝牙权限"
        case .bluetoothOff:
            return "蓝牙未开启"
        case .unsupported:
            return "不支持蓝牙"
        default:
            return "连接错误"
        }
    }
}

#Preview("Unauthorized") {
    ZStack {
        Color.black.ignoresSafeArea()
        ErrorStateView(
            error: .unauthorized,
            onOpenSettings: {},
            onDismiss: {}
        )
    }
}

#Preview("Bluetooth Off") {
    ZStack {
        Color.black.ignoresSafeArea()
        ErrorStateView(
            error: .bluetoothOff,
            onOpenSettings: {},
            onDismiss: {}
        )
    }
}
