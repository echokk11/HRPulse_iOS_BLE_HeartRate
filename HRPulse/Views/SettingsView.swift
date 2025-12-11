import SwiftUI

/// 设置界面视图
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var backgroundService: BackgroundService
    @Binding var appSettings: AppSettings
    @State private var keepScreenAwake: Bool = false
    @State private var showingHealthAlert = false
    @State private var healthAlertMessage = ""
    @State private var showOpenSettingsAction = false
    
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
                    Picker("外观模式", selection: $appSettings.colorScheme) {
                        ForEach(AppSettings.AppColorScheme.allCases, id: \.self) { scheme in
                            Text(scheme.localizedName).tag(scheme)
                        }
                    }
                    .onChange(of: appSettings.colorScheme) { _ in
                        appSettings.save()
                    }
                    .accessibilityLabel("外观模式选择")
                    .accessibilityHint("选择应用显示的颜色主题")

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
                    
                    HStack {
                        Text("体重")
                        Spacer()
                        if let weight = appSettings.weightInKg {
                            Text(String(format: "%.1f kg", weight))
                                .foregroundColor(.secondary)
                        } else {
                            Text("未获得")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("体脂率")
                        Spacer()
                        if let bodyFat = appSettings.bodyFatPercentage {
                            Text(String(format: "%.1f%%", bodyFat))
                                .foregroundColor(.secondary)
                        } else {
                            Text("未获得")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button {
                        fetchHealthData(silent: false)
                    } label: {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                                .foregroundColor(.red)
                            Text("从 Apple 健康同步")
                        }
                    }
                } header: {
                    Text("个人数据")
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
            .alert("健康数据", isPresented: $showingHealthAlert) {
                if showOpenSettingsAction {
                    Button("打开设置") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                Button("确定", role: .cancel) { }
            } message: {
                Text(healthAlertMessage)
            }
        }
        .onAppear {
            // 加载当前屏幕常亮状态
            keepScreenAwake = UIApplication.shared.isIdleTimerDisabled
            fetchIfAlreadyAuthorized()
        }
        .onChange(of: appSettings.age) { _ in
            appSettings.save()
        }
    }
    
    private func fetchIfAlreadyAuthorized() {
        let service = HealthKitService.shared
        switch service.currentReadAuthorizationState() {
        case .authorized:
            fetchHealthData(silent: true, requireAuthorization: false)
        default:
            break
        }
    }
    
    private func fetchHealthData(silent: Bool = false, requireAuthorization: Bool = true) {
        // 重置按钮状态
        showOpenSettingsAction = false
        
        let service = HealthKitService.shared
        let performFetch: () -> Void = {
            let group = DispatchGroup()
            var newWeight: Double?
            var newBodyFat: Double?
            
            group.enter()
            service.fetchLatestWeight { weight, _ in
                newWeight = weight
                group.leave()
            }
            
            group.enter()
            service.fetchLatestBodyFatPercentage { bodyFat, _ in
                newBodyFat = bodyFat
                group.leave()
            }
            
            group.notify(queue: .main) {
                var message = "同步完成\n"
                var hasUpdates = false
                
                if let w = newWeight {
                    appSettings.weightInKg = w
                    message += "体重: \(String(format: "%.1f", w)) kg\n"
                    hasUpdates = true
                }
                
                if let bf = newBodyFat {
                    appSettings.bodyFatPercentage = bf
                    message += "体脂率: \(String(format: "%.1f", bf))%\n"
                    hasUpdates = true
                }
                
                if hasUpdates {
                    appSettings.save()
                    if !silent {
                        healthAlertMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
                        showingHealthAlert = true
                    }
                } else if !silent {
                    healthAlertMessage = "未找到最新的体重或体脂数据，请检查健康 App 中是否有数据或权限是否开启。"
                    showOpenSettingsAction = true
                    showingHealthAlert = true
                }
            }
        }
        
        guard requireAuthorization else {
            performFetch()
            return
        }
        
        service.requestAuthorization { success, _ in
            if success {
                performFetch()
            } else if !silent {
                healthAlertMessage = "无法访问健康数据，请在系统设置中授权"
                showOpenSettingsAction = true
                showingHealthAlert = true
            }
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
