# HRPulse - 实时心率监测应用

一个优雅的 iOS 应用，通过蓝牙连接心率监测设备（如佳明手表），实时显示心率数据，具有精美的动画效果和用户友好的界面。应用突出沉浸式视觉体验：全屏心跳画廊、最佳有氧区间胶囊以及“充能”波纹将真实心率转化为动态、可感知的状态反馈。

## 快速概览

- 🔄 **实时同步**：基于 GATT 0x2A37 推送，BPM / RR-Interval 更新会立刻驱动所有动画节拍。
- 🌫 **断流提示**：未接收到心率推送时，心跳图像自动降为灰色，提醒用户检查连接。
- 🎨 **五种心跳风格**：Scale / Ripple / Neon / EKG / Bars 以 TabView 形式左右滑动切换。
- 🌊 **Charging Wave**：当心率进入最佳有氧区间时，底部绿色能量波纹持续上涌，视觉化“充能”状态。
- 🟩 **最佳有氧胶囊**：根据年龄自动计算最大心率及 60–75% 目标区间，用色带 + 表情指针直观显示实时状态。
- 🕒 **全屏极简 HUD**：顶部显示当前时间，主体聚焦心率内容，轻触即可拉起设置。
- ♿️ **面向可及性**：完全遵循 Dynamic Type、VoiceOver、Reduce Motion 与 Reduce Transparency。

## 功能特性

### 🫀 核心功能
- **实时心率监测** - 通过蓝牙 LE 连接心率设备
- **动态心跳动画** - HeartbeatGallery 中 5 种心跳风格基于 beatPhase 节奏联动
- **脉冲波纹 / Charging Wave** - 针对单心跳或有氧区间的全屏波纹反馈
- **精确数据显示** - 支持 BPM、RR-Interval，同时对 BPM 做指数平滑避免跳变

### 📱 用户界面
- **全屏沉浸式设计** - 顶部时钟 + 中央动画 + 底部胶囊的分层布局
- **心跳画廊** - TabView 左右滑动切换风格，无需额外控件
- **有氧区间胶囊** - 蓝/绿/红渐变与 emoji 指针实时提示心率所处区域
- **Charging Wave 叠层** - 充能波纹位于背景层，blend mode 提供柔和能量感
- **深色/浅色模式 & Dynamic Type** - 自动适配系统主题与字体大小
- **无障碍优化** - 完整 VoiceOver 描述、减少动画等辅助功能支持

### 🔋 性能优化
- **后台运行** - 支持后台持续监测心率
- **低电量模式** - 自动降低动画复杂度节省电量
- **智能帧率** - 根据设备性能调整动画帧率
- **内存优化** - 使用 `drawingGroup()` 优化渲染性能

### 🛠 技术特性
- **自动重连** - 断线后自动尝试重连，支持指数退避
- **数据验证** - 过滤无效的心率数据
- **平滑数值** - 指数移动平均防止 BPM 数字跳跃
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

**HeartAnimationView.swift & HeartbeatGallery.swift**
- 心脏跳动动画、TabView 画廊、波纹/霓虹/波形/柱形风格
- beatPhase 驱动、BPM / RR 节奏感知
- 适配 Reduce Motion / Low Power / Accessibility

**BPMDisplayView.swift + AerobicZoneView.swift**
- 数字滚动动画 + 平滑 BPM 显示
- 自动计算最大心率与 60–75% 目标区间
- 胶囊色带、emoji 指针、状态颜色反馈

**ChargingWaveView.swift**
- TimelineView + Canvas 绘制的多层绿色波纹
- 自下而上流动、随机波动弧度，营造“充能”感
- 通过状态绑定在最佳有氧区间内持续播放

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
1. **启用设备心率广播** - 在佳明手表或其他兼容设备上开启心率广播
2. **打开应用** - 自动扫描、连接最近设备
3. **输入年龄** - 在设置页面登记年龄，自动计算最佳有氧区间
4. **查看实时数据** - 滑动体验多种心跳动画，观察 BPM 与胶囊提示
5. **Charging Wave** - 当心率进入目标区间时，留意屏幕底部的绿色波纹能量

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
