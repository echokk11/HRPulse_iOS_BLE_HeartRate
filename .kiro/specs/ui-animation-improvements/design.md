# Design Document

## Overview

本设计文档描述了 HRPulse iOS 应用 UI 和动画改进的技术实现方案。改进的核心目标是创建一个极简、沉浸式的全屏心率监测界面，通过流畅的动画和直观的视觉反馈提升用户体验，同时支持后台运行和自动重连功能。

### Design Goals

1. **极简主义** - 移除所有非必要元素，只保留心跳动画和 BPM 数值
2. **沉浸式体验** - 全屏显示，隐藏系统 UI 元素
3. **流畅动画** - 60 FPS 性能，真实的心跳效果和脉冲波纹
4. **智能连接** - 后台运行、自动重连、通过颜色传达状态
5. **性能优化** - 低功耗后台运行，流畅的动画性能

## Architecture

### Component Structure

```
HRPulse App
├── Views
│   ├── ContentView (主界面)
│   ├── HeartAnimationView (心跳动画组件)
│   ├── BPMDisplayView (心率数值显示)
│   └── SettingsView (设置界面，手势触发)
├── ViewModels
│   ├── HeartRateViewModel (心率数据管理)
│   └── ConnectionViewModel (连接状态管理)
├── Services
│   ├── HRClient (蓝牙心率客户端 - 已存在，需增强)
│   └── BackgroundService (后台运行管理)
└── Models
    ├── HeartRateData (心率数据模型)
    └── ConnectionState (连接状态枚举)
```

### Data Flow

```
Bluetooth Device (Garmin Watch)
    ↓
HRClient (接收心率数据)
    ↓
HeartRateViewModel (处理和分发数据)
    ↓ ↓
HeartAnimationView    BPMDisplayView
(动画同步)            (数值更新)
```

## Components and Interfaces

### 1. HeartAnimationView

**职责**: 渲染心跳动画，包括缩放效果和脉冲波纹

**接口**:
```swift
struct HeartAnimationView: View {
    let isConnected: Bool          // 连接状态
    let bpm: Int                   // 当前心率
    let rrInterval: Double?        // RR 间隔（可选）
    
    var body: some View
}
```

**动画设计**:
- **心脏缩放动画**: 使用 `spring` 弹性曲线，模拟真实心跳的收缩和舒张
  - 缩放范围: 0.88 → 1.12 (更大的变化幅度)
  - 动画曲线: `.spring(response: 0.3, dampingFraction: 0.6)`
  - 根据 RR-Interval 精确控制节奏
  
- **脉冲波纹效果**: 每次心跳时从心脏中心向外扩散的圆形波纹
  - 3 层波纹，依次延迟触发
  - 透明度: 0.6 → 0
  - 缩放: 1.0 → 2.5
  - 持续时间: 与心跳周期同步

- **颜色状态**:
  - 已连接: `.red` (鲜艳的红色)
  - 断开连接: `.gray.opacity(0.3)` (半透明灰色)
  - 颜色过渡使用 `.animation(.easeInOut(duration: 0.5))`

**性能优化**:
- 使用 `drawingGroup()` 将动画渲染为单个图层
- 避免在动画过程中重新计算布局

### 2. BPMDisplayView

**职责**: 显示心率数值，带滚动动画效果

**接口**:
```swift
struct BPMDisplayView: View {
    let bpm: Int
    let isConnected: Bool
    
    var body: some View
}
```

**设计细节**:
- **字体**: `.system(size: 72, weight: .bold, design: .rounded)`
- **数字滚动动画**: 使用 `AnimatableModifier` 实现平滑的数字过渡
- **布局**: 垂直居中，位于心脏图标下方
- **颜色**: 跟随连接状态（已连接: 主题色，断开: 灰色）

**数字滚动实现**:
```swift
struct AnimatableNumberModifier: AnimatableModifier {
    var number: Double
    
    var animatableData: Double {
        get { number }
        set { number = newValue }
    }
    
    func body(content: Content) -> some View {
        Text("\(Int(number))")
    }
}
```

### 3. ConnectionViewModel

**职责**: 管理连接状态和自动重连逻辑

**接口**:
```swift
class ConnectionViewModel: ObservableObject {
    @Published var connectionState: ConnectionState
    @Published var lastHeartbeatTime: Date?
    
    func startMonitoring()
    func handleDisconnection()
    func attemptReconnection()
}

enum ConnectionState {
    case disconnected
    case scanning
    case connecting
    case connected
}
```

**自动重连策略**:
1. 检测断开: 如果 5 秒内未收到心率数据，判定为断开
2. 重连延迟: 使用指数退避算法
   - 第 1 次: 立即重连
   - 第 2 次: 2 秒后
   - 第 3 次: 5 秒后
   - 第 4 次及以后: 10 秒后
3. 最大重试: 无限次（直到用户手动停止或连接成功）

### 4. BackgroundService

**职责**: 管理后台运行和低功耗模式

**接口**:
```swift
class BackgroundService {
    static let shared = BackgroundService()
    
    var isBackgroundModeEnabled: Bool { get set }
    
    func enableBackgroundMode()
    func disableBackgroundMode()
    func enterLowPowerMode()
}
```

**实现要点**:
- 在 `Info.plist` 中添加 `UIBackgroundModes`: `bluetooth-central`
- 使用 `CBCentralManager` 的后台蓝牙功能
- 在后台时降低动画帧率（从 60 FPS 降至 30 FPS）
- 禁用不必要的 UI 更新

### 5. Enhanced HRClient

**现有功能**: 蓝牙扫描、连接、接收心率数据

**新增功能**:
```swift
extension HRClient {
    // 连接状态回调
    var onConnectionStateChange: ((ConnectionState) -> Void)?
    
    // 断开连接处理
    func centralManager(_ central: CBCentralManager, 
                       didDisconnectPeripheral peripheral: CBPeripheral, 
                       error: Error?)
    
    // 重新扫描和连接
    func reconnect()
    
    // 停止扫描和连接
    func stop()
}
```

## Data Models

### HeartRateData

```swift
struct HeartRateData {
    let bpm: Int
    let rrInterval: Double?
    let timestamp: Date
    
    var isValid: Bool {
        bpm > 0 && bpm < 300
    }
}
```

### AppSettings

```swift
struct AppSettings: Codable {
    var isBackgroundModeEnabled: Bool = true
    var hasSeenOnboarding: Bool = false
    
    // 持久化到 UserDefaults
    static func load() -> AppSettings
    func save()
}
```

## UI Layout Design

### ContentView 布局

```
┌─────────────────────────────────┐
│                                 │  ← 全屏，无状态栏
│                                 │
│                                 │
│          ╔═══════╗              │
│          ║       ║              │  ← 心跳动画
│          ║   ♥   ║              │    (带脉冲波纹)
│          ║       ║              │
│          ╚═══════╝              │
│                                 │
│            120                  │  ← BPM 数值
│            bpm                  │    (大号字体)
│                                 │
│                                 │
│                                 │
│                                 │
└─────────────────────────────────┘
     ↑ 轻触屏幕 → 显示设置
```

### SettingsView 布局

```
┌─────────────────────────────────┐
│  ← 返回                         │
│                                 │
│  设置                           │
│                                 │
│  ┌───────────────────────────┐ │
│  │ 后台运行          [开关]  │ │
│  │ 保持屏幕常亮      [开关]  │ │
│  └───────────────────────────┘ │
│                                 │
│  关于                           │
│  版本 1.1.0                     │
│                                 │
└─────────────────────────────────┘
```

## Animation Specifications

### 1. 心跳缩放动画

```swift
.scaleEffect(isBeating ? 1.12 : 0.88)
.animation(
    .spring(
        response: beatDuration * 0.4,
        dampingFraction: 0.6,
        blendDuration: 0
    ),
    value: isBeating
)
```

**参数说明**:
- `response`: 动画响应时间，设为心跳周期的 40%（收缩阶段）
- `dampingFraction`: 阻尼系数 0.6，产生轻微的弹性效果
- `beatDuration`: 根据 RR-Interval 或 BPM 计算

### 2. 脉冲波纹动画

```swift
ForEach(0..<3) { index in
    Circle()
        .stroke(Color.red.opacity(0.6), lineWidth: 2)
        .scaleEffect(pulseScale)
        .opacity(pulseOpacity)
        .animation(
            .easeOut(duration: beatDuration)
            .delay(Double(index) * 0.1),
            value: pulseScale
        )
}
```

**触发机制**:
- 每次心跳时重置 `pulseScale` 和 `pulseOpacity`
- 3 层波纹依次延迟 0.1 秒触发
- 波纹从心脏边缘开始扩散

### 3. BPM 数字滚动

```swift
Text("\(bpm)")
    .modifier(AnimatableNumberModifier(number: Double(bpm)))
    .animation(.easeInOut(duration: 0.3), value: bpm)
```

### 4. 连接状态颜色过渡

```swift
.foregroundColor(isConnected ? .red : .gray)
.animation(.easeInOut(duration: 0.5), value: isConnected)
```

## Error Handling

### 蓝牙错误处理

| 错误场景 | 处理策略 |
|---------|---------|
| 蓝牙未授权 | 首次启动时请求权限，拒绝后显示设置引导 |
| 蓝牙未开启 | 显示提示，引导用户打开蓝牙 |
| 设备未找到 | 持续扫描，显示灰色心脏 |
| 连接失败 | 自动重试，使用指数退避 |
| 连接断开 | 立即尝试重连，显示灰色心脏 |
| 数据解析错误 | 记录日志，忽略错误数据，继续监听 |

### 数据验证

```swift
func validateHeartRate(_ bpm: Int) -> Bool {
    return bpm >= 30 && bpm <= 250
}

func validateRRInterval(_ rr: Double) -> Bool {
    return rr >= 200 && rr <= 2000  // 30-300 BPM 对应的 RR 范围
}
```

## Performance Optimization

### 动画性能

1. **使用 drawingGroup()**: 将复杂动画渲染为单个图层
2. **避免过度绘制**: 移除不可见的装饰元素
3. **帧率控制**: 
   - 前台: 60 FPS
   - 后台: 30 FPS
   - 低电量模式: 30 FPS

### 内存优化

1. **单例模式**: HRClient 和 BackgroundService 使用单例
2. **弱引用**: 回调闭包使用 `[weak self]` 避免循环引用
3. **及时释放**: 断开连接时清理蓝牙资源

### 电池优化

1. **后台扫描**: 降低扫描频率（从 1 秒降至 5 秒）
2. **连接参数**: 使用较长的连接间隔（100ms）
3. **动画降级**: 后台时禁用波纹效果，只保留基本心跳

## Dark Mode Support

### 颜色适配

```swift
struct ColorTheme {
    static let heartConnected = Color.red
    static let heartDisconnected = Color.gray.opacity(0.3)
    static let bpmText = Color.primary  // 自动适配深色/浅色模式
    static let background = Color(UIColor.systemBackground)
}
```

### 自动切换

- 使用 SwiftUI 的 `@Environment(\.colorScheme)` 自动检测
- 所有颜色使用语义化命名，支持自动适配
- 心脏红色在深色模式下略微调亮，确保可见性

## Accessibility

虽然界面极简，但仍需考虑无障碍支持：

1. **VoiceOver**: 为心率数值添加语音标签
2. **动态字体**: 支持系统字体大小设置
3. **减少动画**: 检测 `UIAccessibility.isReduceMotionEnabled`，简化动画

```swift
if UIAccessibility.isReduceMotionEnabled {
    // 使用简单的淡入淡出替代复杂动画
}
```

## Testing Strategy

### 单元测试

1. **HRClient 数据解析**: 测试各种心率数据格式的解析
2. **ConnectionViewModel**: 测试重连逻辑和状态转换
3. **数据验证**: 测试边界值和异常值处理

### UI 测试

1. **动画流畅性**: 使用 Instruments 测试帧率
2. **状态切换**: 测试连接/断开时的 UI 变化
3. **手势交互**: 测试轻触屏幕显示设置

### 集成测试

1. **蓝牙连接**: 使用真实设备测试连接流程
2. **后台运行**: 测试熄屏后数据接收
3. **自动重连**: 测试断开后重连功能

### 性能测试

1. **电池消耗**: 测试后台运行 1 小时的电量消耗
2. **内存使用**: 监控长时间运行的内存占用
3. **动画性能**: 确保 60 FPS 稳定性

## Implementation Notes

### Info.plist 配置

```xml
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
</array>

<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要蓝牙权限以接收心率数据</string>

<key>UIStatusBarHidden</key>
<true/>

<key>UIViewControllerBasedStatusBarAppearance</key>
<false/>
```

### 首次启动引导

简短的 3 步引导（仅显示一次）：
1. "打开手表的心率广播功能"
2. "应用会自动连接最近的设备"
3. "轻触屏幕可访问设置"

使用半透明遮罩 + 简洁文字，3 秒后自动消失或用户轻触跳过。

## Future Enhancements

虽然不在当前范围内，但可考虑的未来功能：

1. **Apple Watch 版本**: 在手表上显示心率
2. **历史数据**: 记录和查看心率历史
3. **心率区间**: 显示当前心率所在区间（静息/有氧/无氧）
4. **健康应用集成**: 同步数据到 Apple Health
5. **多设备支持**: 同时连接多个心率设备
