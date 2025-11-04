import SwiftUI

struct ContentView: View {
    @StateObject private var vm = HeartRateViewModel()
    @StateObject private var backgroundService = BackgroundService.shared
    @State private var isBeating = false
    @State private var currentBeatDuration: Double = 1.0
    @State private var showSettings = false
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            ColorTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // 心脏动画（包含脉冲波纹）
                HeartAnimationView(
                    isConnected: vm.isConnected,
                    isBeating: isBeating,
                    beatDuration: currentBeatDuration,
                    showPulseEffect: backgroundService.shouldShowPulseEffect,
                    isLowPowerMode: backgroundService.isLowPowerMode
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal, 20)
                
                // BPM 显示组件
                BPMDisplayView(bpm: vm.bpm, isConnected: vm.isConnected)
                    .padding(.top, -30)
                
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
            SettingsView(backgroundService: backgroundService)
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
            let settings = AppSettings.load()
            if !settings.hasSeenOnboarding {
                // 延迟 0.5 秒显示引导，让主界面先加载
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showOnboarding = true
                }
            }
            
            vm.startMonitoring()
            startHeartbeat()
        }
        .onChange(of: vm.heartRateData) { _ in
            updateHeartbeatRhythm()
        }
        .onChange(of: vm.isConnected) { connected in
            if !connected {
                // 断开连接时停止动画
                isBeating = false
            } else {
                // 重新连接时恢复动画
                startHeartbeat()
            }
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
    }

    /// 计算心跳持续时间（秒）
    private func beatDuration() -> Double {
        // 优先使用 RR-Interval 精确计算
        if let rr = vm.rrInterval {
            return max(0.2, min(1.5, rr / 1000.0))
        }
        // 否则根据 BPM 计算
        if vm.bpm > 0 {
            return max(0.3, min(1.5, 60.0 / Double(vm.bpm)))
        }
        return 1.0
    }
    
    /// 启动心跳动画
    private func startHeartbeat() {
        guard vm.isConnected else { return }
        
        currentBeatDuration = beatDuration()
        isBeating = true
        
        // 根据帧率调整动画间隔
        // 60 FPS: 正常间隔
        // 30 FPS: 使用简化的动画时序
        let frameRateMultiplier = backgroundService.currentFrameRate == 30 ? 1.2 : 1.0
        let adjustedDuration = currentBeatDuration * frameRateMultiplier
        
        // 使用定时器驱动心跳节奏
        DispatchQueue.main.asyncAfter(deadline: .now() + adjustedDuration) {
            if vm.isConnected {
                isBeating = false
                DispatchQueue.main.asyncAfter(deadline: .now() + adjustedDuration * 0.1) {
                    if vm.isConnected {
                        startHeartbeat()
                    }
                }
            }
        }
    }
    
    /// 更新心跳节奏（平滑过渡）
    private func updateHeartbeatRhythm() {
        let newDuration = beatDuration()
        
        // 使用动画平滑过渡节奏变化
        withAnimation(.easeInOut(duration: 0.5)) {
            currentBeatDuration = newDuration
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