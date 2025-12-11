import Foundation
import UIKit
import Combine

/// 后台运行服务，管理后台模式和低功耗优化
final class BackgroundService: ObservableObject {
    static let shared = BackgroundService()
    
    // MARK: - Published Properties
    
    /// 应用是否在后台运行
    @Published private(set) var isInBackground: Bool = false
    
    /// 是否启用后台模式
    @Published var isBackgroundModeEnabled: Bool {
        didSet {
            updateBackgroundMode()
        }
    }
    
    /// 当前帧率（FPS）
    @Published private(set) var currentFrameRate: Int = 60
    
    /// 是否处于低电量模式
    @Published private(set) var isLowPowerMode: Bool = false
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var settings: AppSettings
    
    // MARK: - Initialization
    
    private init() {
        // 加载设置
        settings = AppSettings.load()
        isBackgroundModeEnabled = settings.isBackgroundModeEnabled
        
        // 检测低电量模式
        isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        // 监听应用生命周期
        setupNotifications()
    }
    
    // MARK: - Public Methods
    
    /// 启用后台运行模式
    func enableBackgroundMode() {
        isBackgroundModeEnabled = true
        settings.isBackgroundModeEnabled = true
        settings.save()
        
        print("✅ 后台运行模式已启用")
    }
    
    /// 禁用后台运行模式
    func disableBackgroundMode() {
        isBackgroundModeEnabled = false
        settings.isBackgroundModeEnabled = false
        settings.save()
        
        print("⚠️ 后台运行模式已禁用")
    }
    
    /// 进入低功耗模式（后台时调用）
    func enterLowPowerMode() {
        currentFrameRate = 30
        print("🔋 进入低功耗模式：帧率降至 30 FPS")
    }
    
    /// 退出低功耗模式（前台时调用）
    func exitLowPowerMode() {
        // 如果系统处于低电量模式，保持 30 FPS
        currentFrameRate = isLowPowerMode ? 30 : 60
        print("⚡️ 退出低功耗模式：帧率恢复至 \(currentFrameRate) FPS")
    }
    
    /// 是否应该显示波纹效果（后台或低电量模式时禁用）
    var shouldShowPulseEffect: Bool {
        return !isInBackground && !isLowPowerMode
    }
    
    /// 更新低电量模式状态
    func updateLowPowerMode() {
        let newLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        if newLowPowerMode != isLowPowerMode {
            isLowPowerMode = newLowPowerMode
            
            if isLowPowerMode {
                currentFrameRate = 30
                print("🔋 系统进入低电量模式：帧率降至 30 FPS，禁用波纹效果")
            } else if !isInBackground {
                currentFrameRate = 60
                print("⚡️ 系统退出低电量模式：帧率恢复至 60 FPS")
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// 设置应用生命周期通知监听
    private func setupNotifications() {
        // 监听应用进入后台
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleEnterBackground()
            }
            .store(in: &cancellables)
        
        // 监听应用进入前台
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleEnterForeground()
            }
            .store(in: &cancellables)
        
        // 监听应用变为活跃状态
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleBecomeActive()
            }
            .store(in: &cancellables)
        
        // 监听低电量模式变化
        NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)
            .sink { [weak self] _ in
                self?.updateLowPowerMode()
            }
            .store(in: &cancellables)
    }
    
    /// 处理应用进入后台
    private func handleEnterBackground() {
        guard isBackgroundModeEnabled else { return }
        
        isInBackground = true
        enterLowPowerMode()
        
        print("📱 应用进入后台，启用低功耗模式")
    }
    
    /// 处理应用进入前台
    private func handleEnterForeground() {
        isInBackground = false
        exitLowPowerMode()
        
        print("📱 应用进入前台，恢复正常模式")
    }
    
    /// 处理应用变为活跃状态
    private func handleBecomeActive() {
        // 确保前台时使用正常帧率
        if !isInBackground {
            exitLowPowerMode()
        }
    }
    
    /// 更新后台模式设置
    private func updateBackgroundMode() {
        settings.isBackgroundModeEnabled = isBackgroundModeEnabled
        settings.save()
        
        if !isBackgroundModeEnabled && isInBackground {
            // 如果在后台时禁用了后台模式，提示用户
            print("⚠️ 后台模式已禁用，应用在后台时可能无法接收心率数据")
        }
    }
}
