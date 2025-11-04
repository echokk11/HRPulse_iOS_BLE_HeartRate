import Foundation
import Combine
import UIKit

/// 心率视图模型，管理心率数据和连接状态
final class HeartRateViewModel: ObservableObject {
    @Published var heartRateData: HeartRateData?
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastHeartbeatTime: Date?
    @Published var bluetoothError: BluetoothError?
    @Published var showErrorAlert = false
    
    private let hrClient = HRClient.shared
    private var timeoutTimer: Timer?
    private let timeoutInterval: TimeInterval = 5.0 // 5秒超时
    
    /// 当前 BPM 值
    var bpm: Int {
        return heartRateData?.bpm ?? 0
    }
    
    /// 当前 RR-Interval 值（毫秒）
    var rrInterval: Double? {
        return heartRateData?.rrInterval
    }
    
    /// 是否已连接
    var isConnected: Bool {
        return connectionState.isConnected
    }
    
    init() {
        setupHRClient()
    }
    
    /// 配置心率客户端回调
    private func setupHRClient() {
        hrClient.onUpdate = { [weak self] bpm, rrMs in
            self?.handleHeartRateUpdate(bpm: bpm, rrInterval: rrMs)
        }
        
        hrClient.onConnectionStateChange = { [weak self] state in
            self?.handleConnectionStateChange(state)
        }
        
        hrClient.onBluetoothError = { [weak self] error in
            self?.handleBluetoothError(error)
        }
    }
    
    /// 开始监测心率
    func startMonitoring() {
        hrClient.start()
        startTimeoutMonitoring()
    }
    
    /// 停止监测心率
    func stopMonitoring() {
        hrClient.stop()
        stopTimeoutMonitoring()
    }
    
    /// 开始超时监测
    private func startTimeoutMonitoring() {
        stopTimeoutMonitoring()
        
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkForTimeout()
        }
    }
    
    /// 停止超时监测
    private func stopTimeoutMonitoring() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
    
    /// 检查是否超时（5秒未收到数据）
    private func checkForTimeout() {
        guard connectionState == .connected else { return }
        guard let lastTime = lastHeartbeatTime else { return }
        
        let timeSinceLastBeat = Date().timeIntervalSince(lastTime)
        if timeSinceLastBeat > timeoutInterval {
            print("⚠️ 超时检测: \(timeSinceLastBeat)秒未收到数据，触发重连")
            handleDisconnection()
        }
    }
    
    /// 处理断开连接
    func handleDisconnection() {
        connectionState = .disconnected
        heartRateData = nil
        lastHeartbeatTime = nil
        
        // 触发重连
        hrClient.reconnect()
    }
    
    /// 处理心率数据更新
    private func handleHeartRateUpdate(bpm: Int, rrInterval: Double?) {
        // 验证数据
        guard HeartRateData.validateHeartRate(bpm) else {
            print("⚠️ 无效的心率数据: \(bpm) BPM")
            return
        }
        
        if let rr = rrInterval, !HeartRateData.validateRRInterval(rr) {
            print("⚠️ 无效的 RR-Interval: \(rr) ms")
            // 继续使用 BPM，但忽略无效的 RR-Interval
            updateHeartRateData(bpm: bpm, rrInterval: nil)
            return
        }
        
        updateHeartRateData(bpm: bpm, rrInterval: rrInterval)
    }
    
    /// 更新心率数据（在主线程）
    private func updateHeartRateData(bpm: Int, rrInterval: Double?) {
        DispatchQueue.main.async { [weak self] in
            let newData = HeartRateData(bpm: bpm, rrInterval: rrInterval)
            self?.heartRateData = newData
            self?.lastHeartbeatTime = Date()
            
            // 如果收到数据，确保状态为已连接
            if self?.connectionState != .connected {
                self?.connectionState = .connected
            }
            
            // 收到数据后，重置超时监测
            self?.startTimeoutMonitoring()
        }
    }
    
    /// 处理连接状态变化
    private func handleConnectionStateChange(_ state: ConnectionState) {
        DispatchQueue.main.async { [weak self] in
            self?.connectionState = state
            
            // 断开连接时清除心率数据
            if state == .disconnected {
                self?.heartRateData = nil
                self?.lastHeartbeatTime = nil
            }
        }
    }
    
    /// 处理蓝牙错误
    private func handleBluetoothError(_ error: BluetoothError) {
        DispatchQueue.main.async { [weak self] in
            print("🚨 蓝牙错误: \(error.localizedDescription)")
            self?.bluetoothError = error
            
            // 对于需要用户操作的错误，显示警告
            if error.requiresUserAction {
                self?.showErrorAlert = true
            }
        }
    }
    
    /// 清除错误状态
    func clearError() {
        bluetoothError = nil
        showErrorAlert = false
    }
    
    /// 打开系统设置
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
