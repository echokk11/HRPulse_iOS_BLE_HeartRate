# HRPulse - 实时心率监测应用

一个优雅的 iOS 应用，通过蓝牙连接心率监测设备（如佳明手表），实时显示心率数据，具有精美的动画效果和用户友好的界面。

## 功能特性

### 🫀 核心功能
- **实时心率监测** - 通过蓝牙 LE 连接心率设备
- **动态心跳动画** - 根据实际心率节奏跳动的心脏图标
- **脉冲波纹效果** - 视觉化的心跳波纹动画
- **精确数据显示** - 支持 BPM 和 RR-Interval 数据

### 📱 用户界面
- **全屏沉浸式设计** - 隐藏状态栏，专注于心率显示
- **深色/浅色模式** - 自动适配系统主题
- **动态字体支持** - 支持系统辅助功能字体大小
- **无障碍优化** - 完整的 VoiceOver 支持

### 🔋 性能优化
- **后台运行** - 支持后台持续监测心率
- **低电量模式** - 自动降低动画复杂度节省电量
- **智能帧率** - 根据设备性能调整动画帧率
- **内存优化** - 使用 `drawingGroup()` 优化渲染性能

### 🛠 技术特性
- **自动重连** - 断线后自动尝试重连，支持指数退避
- **数据验证** - 过滤无效的心率数据
- **错误处理** - 完善的蓝牙错误处理和用户提示
- **状态恢复** - 支持应用后台恢复时的蓝牙状态恢复

## 技术架构

### 核心组件

#### 🏗 架构模式
- **MVVM 架构** - 使用 SwiftUI 和 ObservableObject
- **单例模式** - HRClient 和 BackgroundService 使用单例
- **委托模式** - 蓝牙事件处理使用委托回调

#### 📦 主要模块

**HRClient.swift**
- 蓝牙中心管理器
- 心率数据解析
- 自动重连机制
- 状态恢复支持

**HeartRateViewModel.swift**
- 心率数据管理
- 连接状态管理
- 超时检测
- 错误处理

**BackgroundService.swift**
- 后台运行管理
- 性能优化控制
- 电量状态监测

#### 🎨 UI 组件

**HeartAnimationView.swift**
- 心脏跳动动画
- 脉冲波纹效果
- 性能优化渲染

**BPMDisplayView.swift**
- 数字滚动动画
- 动态字体支持
- 可访问性优化

**OnboardingView.swift**
- 首次使用引导
- 自动播放介绍

**SettingsView.swift**
- 应用设置界面
- 后台运行开关
- 屏幕常亮选项

## 数据模型

### HeartRateData
```swift
struct HeartRateData {
    let bpm: Int              // 每分钟心跳数
    let rrInterval: Double?   // RR间期（毫秒）
    let timestamp: Date       // 数据时间戳
}
```

### ConnectionState
```swift
enum ConnectionState {
    case disconnected    // 未连接
    case scanning       // 扫描中
    case connecting     // 连接中
    case connected      // 已连接
}
```

### BluetoothError
```swift
enum BluetoothError: Error {
    case unauthorized           // 未授权
    case bluetoothOff          // 蓝牙未开启
    case unsupported           // 不支持蓝牙
    case serviceNotFound       // 服务未找到
    case characteristicNotFound // 特征值未找到
    // ... 更多错误类型
}
```

## 系统要求

- **iOS 15.0+**
- **支持蓝牙 LE 的设备**
- **Xcode 15.0+** (开发)
- **Swift 5.9+** (开发)

## 权限要求

### Info.plist 配置
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>HRPulse 需要蓝牙权限以连接您的心率监测设备</string>

<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
</array>
```

## 支持的设备

- **佳明 (Garmin) 手表** - 支持心率广播功能的型号
- **其他支持标准心率服务的设备** - 符合蓝牙 SIG 心率规范

### 蓝牙服务规范
- **心率服务 UUID**: `180D`
- **心率测量特征值 UUID**: `2A37`

## 安装和使用

### 开发环境设置
1. 克隆项目到本地
2. 使用 Xcode 打开 `HRPulse.xcodeproj`
3. 配置开发者账号和证书
4. 连接 iOS 设备进行测试

### 使用步骤
1. **启用设备心率广播** - 在佳明手表上开启心率广播
2. **打开应用** - 应用会自动扫描并连接最近的心率设备
3. **查看实时数据** - 心脏图标会根据实际心率跳动
4. **访问设置** - 轻触屏幕可打开设置界面

## 性能优化

### 动画优化
- 使用 `drawingGroup()` 减少重绘
- 低电量模式下降低动画复杂度
- 支持减少动画的辅助功能设置

### 内存管理
- 及时释放蓝牙资源
- 使用弱引用避免循环引用
- 合理的定时器管理

### 电量优化
- 后台模式下降低扫描频率
- 智能的重连策略
- 可选的屏幕常亮功能

## 故障排除

### 常见问题

**无法连接设备**
- 确保设备已开启心率广播
- 检查蓝牙权限是否已授权
- 尝试重启蓝牙或重启应用

**数据不准确**
- 确保设备佩戴正确
- 检查设备电量是否充足
- 验证设备是否支持标准心率服务

**应用崩溃**
- 检查 iOS 版本是否符合要求
- 查看控制台日志获取详细错误信息

## 开发计划

### 已完成功能 ✅
- [x] 基础蓝牙连接
- [x] 心率数据显示
- [x] 心跳动画效果
- [x] 后台运行支持
- [x] 错误处理机制
- [x] 用户界面优化
- [x] 性能优化

### 计划中功能 🚧
- [ ] 心率数据历史记录
- [ ] 数据导出功能
- [ ] 更多设备支持
- [ ] Apple Watch 应用
- [ ] 健康数据集成

## 贡献指南

欢迎提交 Issue 和 Pull Request！

### 开发规范
- 遵循 Swift 编码规范
- 添加适当的注释和文档
- 确保代码通过所有测试
- 保持向后兼容性

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 联系方式

如有问题或建议，请通过以下方式联系：
- 提交 GitHub Issue
- 发送邮件至开发者

---

**HRPulse** - 让心率监测变得简单而优雅 ❤️