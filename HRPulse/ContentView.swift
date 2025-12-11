import SwiftUI

struct ContentView: View {
    @StateObject private var vm = HeartRateViewModel()
    @StateObject private var backgroundService = BackgroundService.shared
    @State private var beatPhase = false
    @State private var beatDuration: Double = 1.0
    @State private var beatTimer: DispatchSourceTimer?
    @State private var showSettings = false
    @State private var showOnboarding = false
    @State private var currentTime = Date()
    @State private var appSettings = AppSettings.load()
    @State private var isInAerobicZone = false
    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            ColorTheme.background
                .ignoresSafeArea()
            ChargingWaveView(isActive: isInAerobicZone)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                clockView
                    .padding(.top, 36)
                    .padding(.bottom, 16)
                
                Spacer()
                
                // 心跳动画画廊（左右滑动切换五种风格）
                HeartbeatGallery(
                    bpm: vm.bpm,
                    rrMs: vm.rrInterval,
                    beatPhase: $beatPhase,
                    hasLiveData: hasLiveHeartData
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal, 20)
                
                // BPM 显示组件
                BPMDisplayView(bpm: vm.bpm, isConnected: vm.isConnected)
                    .padding(.top, -30)
                
                AerobicZoneView(
                    bpm: vm.bpm,
                    age: appSettings.age,
                    isConnected: vm.isConnected
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
            }
        }
        .statusBar(hidden: true)
        .contentShape(Rectangle())
        .onTapGesture {
            showSettings = true
        }
        .accessibilityHint("轻触屏幕打开设置")
        .accessibilityAddTraits(.isButton)
        .sheet(isPresented: $showSettings) {
            SettingsView(backgroundService: backgroundService, appSettings: $appSettings)
        }
        .overlay {
            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
            }
        }
        .overlay {
            if vm.showErrorAlert, let error = vm.bluetoothError, error.requiresUserAction {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .overlay {
                        ErrorStateView(
                            error: error,
                            onOpenSettings: {
                                vm.openSettings()
                                vm.clearError()
                            },
                            onDismiss: {
                                vm.clearError()
                            }
                        )
                    }
                    .transition(.opacity)
            }
        }
        .onAppear {
            // 检查是否需要显示首次引导
            appSettings = AppSettings.load()
            if !appSettings.hasSeenOnboarding {
                // 延迟 0.5 秒显示引导，让主界面先加载
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showOnboarding = true
                }
            }
            
            vm.startMonitoring()
            updateAerobicZoneState()
        }
        .onChange(of: vm.heartRateData) { data in
            handleBeatEvent(with: data)
            updateAerobicZoneState()
        }
        .onChange(of: vm.isConnected) { connected in
            if !connected {
                beatPhase = false
                stopBeatTimer()
            } else if let data = vm.heartRateData {
                handleBeatEvent(with: data)
            }
            updateAerobicZoneState()
        }
        .onReceive(clockTimer) { date in
            currentTime = date
        }
        .onDisappear {
            stopBeatTimer()
        }
        .onChange(of: appSettings.age) { _ in
            updateAerobicZoneState()
        }
        .alert("蓝牙错误", isPresented: $vm.showErrorAlert) {
            if let error = vm.bluetoothError {
                if error.requiresUserAction {
                    Button("打开设置") {
                        vm.openSettings()
                        vm.clearError()
                    }
                    Button("取消", role: .cancel) {
                        vm.clearError()
                    }
                } else {
                    Button("确定") {
                        vm.clearError()
                    }
                }
            }
        } message: {
            if let error = vm.bluetoothError {
                Text(error.localizedDescription)
            }
        }
        .preferredColorScheme(preferredColorScheme)
    }

    /// 根据最新 RR/BPM 调整心跳节奏并触发下一次动画
    private func handleBeatEvent(with data: HeartRateData?) {
        guard vm.isConnected, let data else {
            stopBeatTimer()
            beatPhase = false
            return
        }
        beatDuration = computeBeatDuration(from: data)
        triggerBeatPulse()
        scheduleBeatTimer()
        updateAerobicZoneState()
    }
    
    private var formattedTime: String {
        ContentView.clockFormatter.string(from: currentTime)
    }
    
    private var clockView: some View {
        Text(formattedTime)
            .font(.system(size: 54, weight: .medium, design: .monospaced))
            .foregroundStyle(ColorTheme.textPrimary)
            .accessibilityLabel("当前时间")
            .accessibilityValue(formattedTime)
    }
    
    private static let clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    private var hasLiveHeartData: Bool {
        vm.heartRateData != nil && vm.bpm > 0
    }
    
    private func computeBeatDuration(from data: HeartRateData) -> Double {
        if let rr = data.rrInterval {
            return clampDuration(rr / 1000.0)
        }
        let bpm = data.bpm > 0 ? data.bpm : vm.bpm
        guard bpm > 0 else { return 1.0 }
        return clampDuration(60.0 / Double(bpm))
    }
    
    private func clampDuration(_ value: Double) -> Double {
        return max(0.25, min(1.5, value))
    }
    
    private func triggerBeatPulse() {
        withAnimation(.easeInOut(duration: beatDuration * 0.35)) {
            beatPhase.toggle()
        }
    }
    
    private func scheduleBeatTimer() {
        stopBeatTimer()
        let frameAdjust = backgroundService.currentFrameRate == 30 ? 1.2 : 1.0
        let interval = max(0.25, beatDuration * frameAdjust)
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + interval, repeating: interval)
        timer.setEventHandler { [self] in
            triggerBeatPulse()
        }
        timer.resume()
        beatTimer = timer
    }
    
    private func stopBeatTimer() {
        beatTimer?.cancel()
        beatTimer = nil
    }
    
    private func updateAerobicZoneState() {
        guard vm.isConnected, vm.bpm > 0 else {
            isInAerobicZone = false
            return
        }
        let maxHR = clampMaxHeartRate(208.0 - 0.7 * Double(appSettings.age))
        let lower = maxHR * 0.6
        let upper = maxHR * 0.75
        let current = Double(vm.bpm)
        isInAerobicZone = current >= lower && current <= upper
        // isInAerobicZone = true
    }
    
    private func clampMaxHeartRate(_ value: Double) -> Double {
        return max(120, min(205, value))
    }
    
    // MARK: - Color Scheme Helper
    
    private var preferredColorScheme: ColorScheme? {
        switch appSettings.colorScheme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

#Preview("Light Mode") {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}
