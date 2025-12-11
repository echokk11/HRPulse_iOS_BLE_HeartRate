import Foundation
import CoreBluetooth
import UIKit

/// 蓝牙错误类型
/// 
/// 此枚举定义了所有可能的蓝牙错误情况，包括：
/// - 权限问题（未授权）
/// - 硬件问题（蓝牙未开启、不支持）
/// - 连接问题（服务/特征值未找到、连接失败）
/// - 数据问题（数据读取错误、数据无效）
enum BluetoothError: Error {
    case unauthorized           // 未授权
    case bluetoothOff          // 蓝牙未开启
    case unsupported           // 设备不支持蓝牙
    case serviceNotFound       // 未找到心率服务
    case characteristicNotFound // 未找到心率特征值
    case serviceDiscoveryError(String)      // 服务发现错误
    case characteristicDiscoveryError(String) // 特征值发现错误
    case dataReadError(String)  // 数据读取错误
    case invalidData(String)    // 无效数据
    
    var localizedDescription: String {
        switch self {
        case .unauthorized:
            return "需要蓝牙权限才能连接心率设备"
        case .bluetoothOff:
            return "请在设置中开启蓝牙"
        case .unsupported:
            return "您的设备不支持蓝牙功能"
        case .serviceNotFound:
            return "未找到心率服务，请确保设备支持心率监测"
        case .characteristicNotFound:
            return "无法读取心率数据"
        case .serviceDiscoveryError(let message):
            return "服务发现失败: \(message)"
        case .characteristicDiscoveryError(let message):
            return "特征值发现失败: \(message)"
        case .dataReadError(let message):
            return "数据读取失败: \(message)"
        case .invalidData(let message):
            return "数据无效: \(message)"
        }
    }
    
    /// 是否需要用户操作
    var requiresUserAction: Bool {
        switch self {
        case .unauthorized, .bluetoothOff:
            return true
        default:
            return false
        }
    }
}

final class HRClient: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let shared = HRClient()

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private let heartRateService = CBUUID(string: "180D")
    private let heartRateMeasurement = CBUUID(string: "2A37")
    
    // 重连相关属性
    private var reconnectAttempts = 0
    private var reconnectTimer: Timer?
    
    // 扫描频率控制（后台降低扫描频率以节省电量）
    private var isInBackground = false
    private var scanInterval: TimeInterval {
        return isInBackground ? 5.0 : 1.0
    }

    var onUpdate: ((Int, Double?) -> Void)?
    var onConnectionStateChange: ((ConnectionState) -> Void)?
    var onBluetoothError: ((BluetoothError) -> Void)?

    override init() {
        super.init()
        // 使用较长的连接间隔以节省电量
        self.central = CBCentralManager(
            delegate: self, 
            queue: .main, 
            options: [
                CBCentralManagerOptionShowPowerAlertKey: true,
                CBCentralManagerOptionRestoreIdentifierKey: "HRPulseClient"
            ]
        )
        
        // 监听应用生命周期以调整扫描频率
        setupBackgroundNotifications()
    }
    
    deinit {
        // 清理资源
        cleanup()
    }
    
    /// 设置后台通知监听
    private func setupBackgroundNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func handleEnterBackground() {
        isInBackground = true
        print("🔋 HRClient: 进入后台，降低扫描频率至 \(scanInterval) 秒")
    }
    
    @objc private func handleEnterForeground() {
        isInBackground = false
        print("⚡️ HRClient: 进入前台，恢复扫描频率至 \(scanInterval) 秒")
    }
    
    /// 清理资源
    private func cleanup() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        
        if let p = peripheral {
            central.cancelPeripheralConnection(p)
            peripheral = nil
        }
        
        central.stopScan()
        
        NotificationCenter.default.removeObserver(self)
        
        print("🧹 HRClient: 资源已清理")
    }

    func start() {
        // 检查蓝牙状态
        guard central.state == .poweredOn else {
            print("⚠️ 蓝牙未就绪，当前状态: \(central.state.rawValue)")
            
            // 根据状态触发相应的错误
            switch central.state {
            case .poweredOff:
                onBluetoothError?(.bluetoothOff)
            case .unauthorized:
                onBluetoothError?(.unauthorized)
            case .unsupported:
                onBluetoothError?(.unsupported)
            default:
                break
            }
            return
        }
        
        print("🔍 开始扫描心率设备...")
        onConnectionStateChange?(.scanning)
        central.scanForPeripherals(withServices: [heartRateService], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    /// 获取当前蓝牙状态
    var bluetoothState: CBManagerState {
        return central.state
    }
    
    /// 检查蓝牙是否可用
    var isBluetoothAvailable: Bool {
        return central.state == .poweredOn
    }
    
    func stop() {
        // 取消重连定时器
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        reconnectAttempts = 0
        
        // 停止扫描
        central.stopScan()
        
        // 断开连接并清理外设引用
        if let p = peripheral {
            // 取消通知订阅
            if let services = p.services {
                for service in services {
                    if let characteristics = service.characteristics {
                        for characteristic in characteristics {
                            if characteristic.isNotifying {
                                p.setNotifyValue(false, for: characteristic)
                            }
                        }
                    }
                }
            }
            
            central.cancelPeripheralConnection(p)
            peripheral = nil
        }
        
        onConnectionStateChange?(.disconnected)
        print("🛑 HRClient: 已停止，资源已清理")
    }
    
    /// 重新连接（用于自动重连）
    func reconnect() {
        guard central.state == .poweredOn else { 
            print("⚠️ 蓝牙未开启，无法重连")
            return 
        }
        
        // 取消现有连接
        if let p = peripheral {
            central.cancelPeripheralConnection(p)
            peripheral = nil
        }
        
        // 停止现有扫描
        central.stopScan()
        
        // 开始新的扫描
        start()
    }
    
    /// 尝试自动重连（带指数退避）
    private func attemptReconnection() {
        // 取消之前的定时器
        reconnectTimer?.invalidate()
        
        // 计算延迟时间（指数退避：0秒、2秒、5秒、10秒）
        let delay: TimeInterval
        switch reconnectAttempts {
        case 0:
            delay = 0  // 立即重连
        case 1:
            delay = 2  // 2秒后
        case 2:
            delay = 5  // 5秒后
        default:
            delay = 10 // 10秒后（最大延迟）
        }
        
        print("🔄 将在 \(delay) 秒后尝试第 \(reconnectAttempts + 1) 次重连")
        
        if delay == 0 {
            reconnect()
            reconnectAttempts += 1
        } else {
            reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                self?.reconnect()
                self?.reconnectAttempts += 1
            }
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("✅ 蓝牙已开启")
            start()
        case .poweredOff:
            print("❌ 蓝牙已关闭")
            onConnectionStateChange?(.disconnected)
            onBluetoothError?(.bluetoothOff)
        case .unauthorized:
            print("❌ 蓝牙未授权")
            onConnectionStateChange?(.disconnected)
            onBluetoothError?(.unauthorized)
        case .unsupported:
            print("❌ 设备不支持蓝牙")
            onConnectionStateChange?(.disconnected)
            onBluetoothError?(.unsupported)
        case .resetting:
            print("⚠️ 蓝牙正在重置")
            onConnectionStateChange?(.disconnected)
        case .unknown:
            print("⚠️ 蓝牙状态未知")
            onConnectionStateChange?(.disconnected)
        @unknown default:
            print("⚠️ 未知的蓝牙状态")
            onConnectionStateChange?(.disconnected)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover p: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // 记录发现的设备信息
        let deviceName = p.name ?? "未知设备"
        print("📱 发现心率设备: \(deviceName), RSSI: \(RSSI)")
        
        // 检查信号强度，避免连接信号太弱的设备
        if RSSI.intValue < -90 {
            print("⚠️ 设备信号太弱 (RSSI: \(RSSI))，继续扫描...")
            return
        }
        
        self.peripheral = p
        central.stopScan()
        onConnectionStateChange?(.connecting)
        
        // 使用较长的连接间隔以节省电量（100ms）
        let connectionOptions: [String: Any] = [
            CBConnectPeripheralOptionNotifyOnConnectionKey: true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
            CBConnectPeripheralOptionNotifyOnNotificationKey: true
        ]
        
        print("🔗 正在连接到 \(deviceName)...")
        central.connect(p, options: connectionOptions)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // 连接成功，重置重连计数
        reconnectAttempts = 0
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        
        onConnectionStateChange?(.connected)
        peripheral.delegate = self
        
        // 发现服务
        peripheral.discoverServices([heartRateService])
        
        print("✅ HRClient: 已连接到设备")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("❌ 设备断开连接: \(error?.localizedDescription ?? "无错误")")
        
        // 清理外设引用
        if self.peripheral == peripheral {
            self.peripheral = nil
        }
        
        onConnectionStateChange?(.disconnected)
        
        // 自动尝试重连
        attemptReconnection()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ 连接失败: \(error?.localizedDescription ?? "未知错误")")
        
        // 清理外设引用
        if self.peripheral == peripheral {
            self.peripheral = nil
        }
        
        onConnectionStateChange?(.disconnected)
        
        // 连接失败也尝试重连
        attemptReconnection()
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        // 恢复蓝牙状态（用于后台状态恢复）
        print("🔄 恢复蓝牙状态")
        
        // 恢复外设连接
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for peripheral in peripherals {
                print("📱 恢复外设: \(peripheral.name ?? "未知设备")")
                self.peripheral = peripheral
                peripheral.delegate = self
                
                // 如果外设已连接，发现服务
                if peripheral.state == .connected {
                    onConnectionStateChange?(.connected)
                    peripheral.discoverServices([heartRateService])
                }
            }
        }
        
        // 恢复扫描状态
        if let scanServices = dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID] {
            print("🔍 恢复扫描服务: \(scanServices)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("❌ 发现服务失败: \(error.localizedDescription)")
            onBluetoothError?(.serviceDiscoveryError(error.localizedDescription))
            return
        }
        
        guard let svc = peripheral.services?.first(where: { $0.uuid == heartRateService }) else {
            print("⚠️ 未找到心率服务")
            onBluetoothError?(.serviceNotFound)
            return
        }
        
        peripheral.discoverCharacteristics([heartRateMeasurement], for: svc)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("❌ 发现特征值失败: \(error.localizedDescription)")
            onBluetoothError?(.characteristicDiscoveryError(error.localizedDescription))
            return
        }
        
        guard let ch = service.characteristics?.first(where: { $0.uuid == heartRateMeasurement }) else {
            print("⚠️ 未找到心率测量特征值")
            onBluetoothError?(.characteristicNotFound)
            return
        }
        
        peripheral.setNotifyValue(true, for: ch)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // 处理读取错误
        if let error = error {
            print("❌ 读取特征值失败: \(error.localizedDescription)")
            onBluetoothError?(.dataReadError(error.localizedDescription))
            return
        }
        
        guard let data = characteristic.value else {
            print("⚠️ 特征值为空")
            return
        }
        
        // 解析心率数据
        let (bpm, rrMs) = Self.parseHeartRate(from: data)
        
        // 验证数据有效性
        guard HeartRateData.validateHeartRate(bpm) else {
            print("⚠️ 接收到无效的心率数据: \(bpm) BPM，已过滤")
            onBluetoothError?(.invalidData("心率值超出范围: \(bpm) BPM"))
            return
        }
        
        // 验证 RR-Interval（如果存在）
        if let rr = rrMs, !HeartRateData.validateRRInterval(rr) {
            print("⚠️ 接收到无效的 RR-Interval: \(rr) ms，仅使用 BPM")
            // 继续使用有效的 BPM，但不传递无效的 RR-Interval
            onUpdate?(bpm, nil)
            return
        }
        
        // 数据有效，传递给回调
        onUpdate?(bpm, rrMs)
    }

    static func parseHeartRate(from data: Data) -> (Int, Double?) {
        let bytes = [UInt8](data)
        
        // 验证数据长度
        guard !bytes.isEmpty else {
            print("⚠️ 心率数据为空")
            return (0, nil)
        }
        
        guard bytes.count >= 2 else {
            print("⚠️ 心率数据长度不足: \(bytes.count) 字节")
            return (0, nil)
        }
        
        let flags = bytes[0]
        var idx = 1

        // 解析心率值
        let isUInt16 = (flags & 0x01) != 0
        let hr: Int
        if isUInt16 {
            // 16位心率值
            if bytes.count >= 3 {
                hr = Int(UInt16(bytes[1]) | (UInt16(bytes[2]) << 8))
                idx = 3
            } else {
                print("⚠️ 16位心率数据长度不足")
                return (0, nil)
            }
        } else {
            // 8位心率值
            hr = Int(bytes[1])
            idx = 2
        }

        // Energy Expended present? bit3
        let eePresent = (flags & 0x08) != 0
        if eePresent {
            // 跳过能量消耗字段（2字节）
            if bytes.count >= idx + 2 {
                idx += 2
            } else {
                print("⚠️ 能量消耗字段长度不足")
                // 继续处理，但不解析 RR-Interval
                return (hr, nil)
            }
        }

        // RR-Interval present? bit4
        let rrPresent = (flags & 0x10) != 0
        var rrMs: Double? = nil
        if rrPresent {
            if bytes.count >= idx + 2 {
                let rr = UInt16(bytes[idx]) | (UInt16(bytes[idx+1]) << 8)
                // RR-Interval 单位是 1/1024 秒，转换为毫秒
                rrMs = Double(rr) * (1000.0 / 1024.0)
                
                // 验证 RR-Interval 是否合理
                if let rr = rrMs, rr < 100 || rr > 3000 {
                    print("⚠️ RR-Interval 超出合理范围: \(rr) ms")
                    rrMs = nil
                }
            } else {
                print("⚠️ RR-Interval 字段长度不足")
            }
        }
        
        return (hr, rrMs)
    }
}