# Requirements Document

## Introduction

本文档定义了 HRPulse iOS 应用的 UI 设计和动画效果改进需求。HRPulse 是一个通过蓝牙接收佳明手表心率数据并实时显示的应用。当前版本具有基本的心跳动画和数据显示功能，本次改进旨在提升用户体验，使界面更加现代化、动画更加流畅自然，并增强视觉反馈。

## Glossary

- **HRPulse_App**: 接收并显示心率数据的 iOS 应用系统
- **Heart_Rate_Display**: 显示当前心率（BPM）的 UI 组件
- **Heart_Animation**: 模拟心跳的动画效果组件
- **BPM**: Beats Per Minute，每分钟心跳次数
- **RR_Interval**: 连续两次心跳之间的时间间隔（毫秒）
- **Bluetooth_Device**: 通过蓝牙连接的心率监测设备（如佳明手表）
- **Background_Mode**: 应用在后台运行时保持蓝牙连接的模式
- **Screen_Lock**: iOS 设备屏幕锁定状态

## Requirements

### Requirement 1

**User Story:** 作为用户，我希望看到极简的全屏界面设计，以便专注于心率数据和动画

#### Acceptance Criteria

1. THE HRPulse_App SHALL 使用全屏布局，心跳动画和 BPM 数据占据整个屏幕
2. THE Heart_Rate_Display SHALL 仅显示心跳动画和 BPM 数值，隐藏所有其他信息和说明文字
3. THE HRPulse_App SHALL 支持深色模式和浅色模式的自适应显示
4. THE Heart_Rate_Display SHALL 使用简洁的视觉设计，避免多余的装饰元素

### Requirement 2

**User Story:** 作为用户，我希望心跳动画更加流畅和真实，以便更直观地感受心率变化

#### Acceptance Criteria

1. WHEN Heart_Animation 播放时，THE HRPulse_App SHALL 使用弹性动画曲线模拟真实心跳效果
2. WHEN RR_Interval 数据可用时，THE Heart_Animation SHALL 根据实际心跳间隔精确同步动画节奏
3. THE Heart_Animation SHALL 在心率变化时平滑过渡动画速度，避免突兀的节奏变化
4. THE Heart_Animation SHALL 包含脉冲波纹效果，增强视觉冲击力

### Requirement 3

**User Story:** 作为用户，我希望通过心脏图标颜色了解连接状态，以便快速识别设备是否正常工作

#### Acceptance Criteria

1. WHEN Bluetooth_Device 已连接且接收数据时，THE Heart_Animation SHALL 显示为红色
2. WHEN Bluetooth_Device 断开连接时，THE Heart_Animation SHALL 显示为灰色并停止跳动
3. WHEN Bluetooth_Device 断开连接时，THE HRPulse_App SHALL 自动尝试重新连接
4. THE HRPulse_App SHALL 不显示文字连接状态，仅通过心脏颜色传达状态

### Requirement 4

**User Story:** 作为用户，我希望心率数据以简洁方式呈现，以便快速读取当前心率

#### Acceptance Criteria

1. WHEN BPM 数据更新时，THE Heart_Rate_Display SHALL 使用数字滚动动画平滑过渡
2. THE Heart_Rate_Display SHALL 仅显示 BPM 数值和单位，不显示其他数据
3. THE Heart_Rate_Display SHALL 使用大号字体显示 BPM，确保在远距离也能清晰阅读
4. THE Heart_Rate_Display SHALL 将 BPM 数值放置在屏幕中心或心脏图标下方

### Requirement 5

**User Story:** 作为用户，我希望界面响应更加灵敏，以便获得流畅的交互体验

#### Acceptance Criteria

1. WHEN 用户与界面交互时，THE HRPulse_App SHALL 在 100 毫秒内提供视觉反馈
2. THE HRPulse_App SHALL 保持 60 FPS 的动画帧率，确保流畅性
3. WHEN 数据更新时，THE HRPulse_App SHALL 使用微动画过渡，避免界面闪烁
4. THE HRPulse_App SHALL 优化渲染性能，确保在低电量模式下仍能流畅运行

### Requirement 6

**User Story:** 作为用户，我希望应用在熄屏和后台时保持连接，以便持续监测心率

#### Acceptance Criteria

1. THE HRPulse_App SHALL 默认启用后台蓝牙连接模式，在熄屏时保持与 Bluetooth_Device 的连接
2. WHEN Screen_Lock 激活时，THE HRPulse_App SHALL 继续接收和处理心率数据
3. THE HRPulse_App SHALL 在后台运行时保持低功耗模式，优化电池使用
4. THE HRPulse_App SHALL 在设置中提供选项，允许用户禁用后台运行功能

### Requirement 7

**User Story:** 作为用户，我希望界面保持简洁，以便获得沉浸式的使用体验

#### Acceptance Criteria

1. THE HRPulse_App SHALL 移除所有说明文字和连接指南，仅保留核心功能
2. THE HRPulse_App SHALL 隐藏状态栏和导航栏，提供完全沉浸式体验
3. THE HRPulse_App SHALL 使用手势交互（如轻触屏幕）访问设置，而不是显示按钮
4. THE HRPulse_App SHALL 在首次启动时显示简短的引导提示，之后不再显示
