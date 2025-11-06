import SwiftUI

/// 设置界面视图
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var backgroundService: BackgroundService
    @Binding var appSettings: AppSettings
    @State private var keepScreenAwake: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                // 后台运行设置
                Section {
                    Toggle("后台运行", isOn: $backgroundService.isBackgroundModeEnabled)
                        .accessibilityLabel("后台运行")
                        .accessibilityHint("启用后，应用在熄屏时继续接收心率数据")
                } header: {
                    Text("蓝牙连接")
                } footer: {
                    Text("启用后，应用在熄屏时继续接收心率数据")
                }
                
                // 屏幕常亮设置（可选）
                Section {
                    Toggle("保持屏幕常亮", isOn: $keepScreenAwake)
                        .onChange(of: keepScreenAwake) { newValue in
                            UIApplication.shared.isIdleTimerDisabled = newValue
                        }
                        .accessibilityLabel("保持屏幕常亮")
                        .accessibilityHint("防止屏幕自动锁定，可能增加电池消耗")
                } header: {
                    Text("显示")
                } footer: {
                    Text("防止屏幕自动锁定，可能增加电池消耗")
                }
                
                Section {
                    Stepper(value: $appSettings.age, in: 16...85, step: 1) {
                        Text("年龄 \(appSettings.age) 岁")
                    }
                    .accessibilityLabel("年龄设置")
                    .accessibilityHint("用于计算最佳有氧心率区间")
                } header: {
                    Text("个人参数")
                } footer: {
                    Text("将根据年龄自动估算最佳有氧心率区间")
                }
                
                // 关于信息
                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("构建版本")
                        Spacer()
                        Text(buildNumber)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("关于")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") {
                        dismiss()
                    }
                    .accessibilityLabel("完成")
                    .accessibilityHint("关闭设置并返回主界面")
                }
            }
        }
        .onAppear {
            // 加载当前屏幕常亮状态
            keepScreenAwake = UIApplication.shared.isIdleTimerDisabled
        }
        .onChange(of: appSettings.age) { _ in
            appSettings.save()
        }
    }
    
    // MARK: - App Version Info
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

#Preview {
    SettingsView(backgroundService: BackgroundService.shared, appSettings: .constant(AppSettings()))
}
