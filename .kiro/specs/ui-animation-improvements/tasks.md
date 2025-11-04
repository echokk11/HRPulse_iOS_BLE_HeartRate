# Implementation Plan

## Task Overview

本实现计划将 UI 和动画改进分解为增量式的编码任务。每个任务都是独立可执行的，并在前一个任务的基础上构建。任务按照从核心功能到增强功能的顺序排列。

---

- [x] 1. 重构数据模型和视图模型架构
  - 创建 `HeartRateData` 模型，封装 BPM 和 RR-Interval 数据
  - 创建 `ConnectionState` 枚举，定义连接状态（disconnected, scanning, connecting, connected）
  - 重构 `HeartRateModel` 为 `HeartRateViewModel`，添加连接状态管理
  - 添加数据验证方法（validateHeartRate 和 validateRRInterval）
  - _Requirements: 1.2, 3.1, 3.2, 4.1_

- [x] 2. 实现极简全屏 UI 布局
  - [x] 2.1 创建新的 ContentView 布局
    - 移除所有说明文字和连接指南
    - 实现垂直居中的全屏布局（心脏动画 + BPM 数值）
    - 隐藏状态栏（修改 Info.plist 和 SwiftUI 配置）
    - 移除圆形边框和其他装饰元素
    - _Requirements: 1.1, 1.2, 7.1, 7.2_

  - [x] 2.2 实现 BPMDisplayView 组件
    - 创建独立的 BPM 显示组件
    - 使用大号字体（72pt, bold, rounded design）
    - 实现连接状态颜色适配（已连接: primary, 断开: gray）
    - 将 BPM 放置在心脏图标下方
    - _Requirements: 4.2, 4.3, 4.4_

- [x] 3. 增强心跳动画效果
  - [x] 3.1 改进心脏缩放动画
    - 将缩放范围从 0.92-1.12 调整为 0.88-1.12（更大幅度）
    - 使用 Spring 动画曲线替代 easeInOut（response: 0.3, dampingFraction: 0.6）
    - 根据 RR-Interval 精确计算动画持续时间
    - 实现平滑的节奏过渡，避免突兀变化
    - _Requirements: 2.1, 2.2, 2.3_

  - [x] 3.2 实现脉冲波纹效果
    - 创建 3 层同心圆波纹，从心脏边缘向外扩散
    - 实现波纹动画（缩放 1.0 → 2.5，透明度 0.6 → 0）
    - 每层波纹延迟 0.1 秒触发
    - 波纹动画与心跳周期同步
    - 使用 drawingGroup() 优化渲染性能
    - _Requirements: 2.4, 5.2_

- [x] 4. 实现连接状态视觉反馈
  - [x] 4.1 添加心脏颜色状态管理
    - 已连接时显示红色心脏
    - 断开连接时显示灰色半透明心脏（opacity: 0.3）
    - 实现颜色平滑过渡动画（easeInOut, 0.5 秒）
    - _Requirements: 3.1, 3.2_

  - [x] 4.2 实现断开时停止动画
    - 当连接断开时，停止心跳缩放动画
    - 当连接断开时，停止脉冲波纹效果
    - 保持心脏图标静止显示
    - _Requirements: 3.2_

- [x] 5. 实现 BPM 数字滚动动画
  - 创建 `AnimatableNumberModifier` 实现数字平滑过渡
  - 应用到 BPM 数值显示
  - 使用 easeInOut 动画曲线，持续时间 0.3 秒
  - 确保动画流畅，避免闪烁
  - _Requirements: 4.1, 5.3_

- [x] 6. 增强 HRClient 连接管理
  - [x] 6.1 添加连接状态回调
    - 添加 `onConnectionStateChange` 回调闭包
    - 在连接、断开、扫描等事件时触发回调
    - 实现 `didDisconnectPeripheral` 委托方法
    - _Requirements: 3.3_

  - [x] 6.2 实现自动重连机制
    - 创建 `reconnect()` 方法重新扫描和连接
    - 实现指数退避算法（立即、2 秒、5 秒、10 秒）
    - 在 ViewModel 中添加重连逻辑
    - 添加 5 秒超时检测（未收到数据判定为断开）
    - _Requirements: 3.3_

  - [x] 6.3 添加停止扫描方法
    - 实现 `stop()` 方法停止扫描和断开连接
    - 清理蓝牙资源
    - _Requirements: 3.3_

- [x] 7. 实现后台运行功能
  - [x] 7.1 配置后台蓝牙模式
    - 在 Info.plist 中添加 `UIBackgroundModes`: `bluetooth-central`
    - 添加蓝牙权限描述 `NSBluetoothAlwaysUsageDescription`
    - _Requirements: 6.1, 6.2_

  - [x] 7.2 实现 BackgroundService
    - 创建 `BackgroundService` 单例类
    - 实现 `enableBackgroundMode()` 和 `disableBackgroundMode()` 方法
    - 实现低功耗模式（后台降低动画帧率至 30 FPS）
    - 在后台时禁用波纹效果，只保留基本心跳
    - _Requirements: 6.3_

  - [x] 7.3 创建 AppSettings 模型
    - 创建 `AppSettings` 结构体，包含 `isBackgroundModeEnabled` 和 `hasSeenOnboarding`
    - 实现 UserDefaults 持久化（load 和 save 方法）
    - 默认启用后台模式
    - _Requirements: 6.1, 6.4_

- [x] 8. 实现设置界面
  - [x] 8.1 创建 SettingsView
    - 创建简洁的设置界面
    - 添加"后台运行"开关
    - 添加"保持屏幕常亮"开关（可选）
    - 添加关于信息和版本号
    - 实现返回按钮
    - _Requirements: 6.4, 7.3_

  - [x] 8.2 实现手势触发设置
    - 在 ContentView 添加轻触手势识别
    - 轻触屏幕时以 sheet 方式显示 SettingsView
    - 实现平滑的进入和退出动画
    - _Requirements: 7.3_

- [x] 9. 实现首次启动引导
  - 创建 OnboardingView 组件
  - 显示 3 步简短引导（手表设置、自动连接、手势设置）
  - 使用半透明遮罩和简洁文字
  - 3 秒后自动消失或用户轻触跳过
  - 使用 AppSettings 记录是否已显示引导
  - _Requirements: 7.4_

- [x] 10. 深色模式适配
  - 定义 ColorTheme 结构体，包含语义化颜色
  - 使用 `Color.primary` 和 `Color(UIColor.systemBackground)` 自动适配
  - 在深色模式下调亮心脏红色，确保可见性
  - 测试深色和浅色模式下的视觉效果
  - _Requirements: 1.3_

- [x] 11. 性能优化
  - [x] 11.1 动画性能优化
    - 为复杂动画添加 `drawingGroup()` 修饰符
    - 实现帧率控制（前台 60 FPS，后台 30 FPS）
    - 在低电量模式下降低动画复杂度
    - _Requirements: 5.2, 5.4_

  - [x] 11.2 内存和电池优化
    - 确保所有回调使用 `[weak self]` 避免循环引用
    - 在后台降低蓝牙扫描频率（从 1 秒降至 5 秒）
    - 使用较长的蓝牙连接间隔（100ms）
    - 断开连接时及时清理资源
    - _Requirements: 5.4, 6.3_

- [x] 12. 无障碍支持
  - 为 BPM 数值添加 VoiceOver 标签
  - 支持动态字体大小（使用 `.dynamicTypeSize`）
  - 检测 `UIAccessibility.isReduceMotionEnabled`，简化动画
  - 为手势交互添加无障碍提示
  - _Requirements: 5.1_

- [x] 13. 错误处理和边界情况
  - 实现蓝牙未授权时的权限请求和引导
  - 实现蓝牙未开启时的提示
  - 添加数据验证，过滤异常心率值（30-250 BPM）
  - 添加 RR-Interval 验证（200-2000 ms）
  - 处理连接失败和数据解析错误
  - _Requirements: 3.3, 5.1_

---

## Implementation Notes

- 每个任务应独立完成并测试后再进行下一个
- 优先实现核心功能（任务 1-6），再实现增强功能（任务 7-13）
- 在实现动画时，使用 Xcode Previews 快速迭代视觉效果
- 使用真实的佳明手表测试蓝牙连接和数据接收
- 定期使用 Instruments 检查性能和内存使用

## Testing Checklist

完成所有任务后，进行以下测试：

- [ ] 连接佳明手表，验证心率数据正常显示
- [ ] 验证心跳动画与实际心率同步
- [ ] 测试断开连接时的灰色显示和自动重连
- [ ] 测试后台运行（熄屏后继续接收数据）
- [ ] 测试深色和浅色模式切换
- [ ] 测试手势触发设置界面
- [ ] 测试首次启动引导
- [ ] 使用 Instruments 验证 60 FPS 性能
- [ ] 测试长时间运行的电池消耗
- [ ] 测试 VoiceOver 和无障碍功能
