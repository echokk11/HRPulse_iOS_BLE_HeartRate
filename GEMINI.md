# HRPulse - Real-time Heart Rate Monitoring iOS App

## Project Overview

**HRPulse** is a native iOS application designed for real-time heart rate monitoring via Bluetooth Low Energy (BLE). It connects to standard heart rate monitors (e.g., Garmin watches, chest straps) and provides an immersive visual experience.

The app emphasizes visual feedback through:
*   **Dynamic Animations:** 5 styles (Scale, Ripple, Neon, EKG, Bars) driven by real-time heart beats.
*   **Aerobic Zone Indicators:** Visual cues (capsules, colors, emojis) based on calculated max heart rate.
*   **Immersive Effects:** A "Charging Wave" effect when in the optimal aerobic zone.

## Tech Stack & Architecture

*   **Platform:** iOS 15.0+
*   **Language:** Swift 5.9+
*   **UI Framework:** SwiftUI
*   **Bluetooth:** CoreBluetooth (Central Mode)
*   **Async/Data Flow:** Combine, ObservableObject
*   **Architecture Pattern:** MVVM (Model-View-ViewModel)

### Key Architectural Components

*   **`HRClient` (Singleton):** The core Bluetooth manager.
    *   Handles scanning, connecting, and maintaining connections to BLE peripherals.
    *   Parses standard GATT Heart Rate Measurement data (Service `0x180D`, Characteristic `0x2A37`).
    *   Implements automatic reconnection with exponential backoff.
    *   Supports State Restoration (`CBCentralManagerOptionRestoreIdentifierKey`) for background continuity.
*   **`HeartRateViewModel`:** The bridge between data and UI.
    *   Subscribes to `HRClient` updates.
    *   Applies exponential smoothing to BPM values to prevent jitter.
    *   Monitors data freshness (5-second timeout detection).
*   **`BackgroundService` (Singleton):** Manages app lifecycle and performance.
    *   Throttles animation frame rates (60fps -> 30fps) when in background or Low Power Mode.
    *   Toggles the "Pulse Effect" to save battery.

## Key Files & Directories

| File/Directory | Description |
| :--- | :--- |
| **`HRPulse/HRPulse.swift`** | App entry point. |
| **`HRPulse/HRClient.swift`** | **CRITICAL.** Handles all BLE logic (Scan, Connect, Reconnect, Parse). |
| **`HRPulse/ViewModels/HeartRateViewModel.swift`** | Main business logic. Handles data smoothing and connection state. |
| **`HRPulse/Services/BackgroundService.swift`** | Manages background tasks and battery optimization logic. |
| **`HRPulse/Models/HeartRateData.swift`** | Data model for BPM and RR-Intervals with validation logic. |
| **`HRPulse/Info.plist`** | Contains essential BLE permissions (`NSBluetoothAlwaysUsageDescription`) and Background Modes. |
| **`HRPulse/Views/`** | SwiftUI Views for the UI (HeartAnimationView, HeartbeatGallery, etc.). |

## Build & Run Instructions

1.  **Open Project:** Double-click `HRPulse.xcodeproj` to open in Xcode.
2.  **Signing:** Ensure your Apple Developer Team is selected in the "Signing & Capabilities" tab of the project target.
3.  **Device Requirement:** **You must use a physical iOS device.** The iOS Simulator **does not** support Bluetooth.
4.  **Permissions:** On first launch, grant Bluetooth permissions when prompted.
5.  **Hardware:** Ensure you have a BLE Heart Rate Monitor (e.g., Garmin Watch broadcasting HR) available and in pairing/broadcasting mode.

## Development Conventions

*   **BLE Handling:**
    *   Service UUID: `180D`
    *   Characteristic UUID: `2A37`
    *   Data Parsing: Supports both 8-bit and 16-bit HR formats, plus RR-Intervals.
*   **Data Validation:**
    *   BPM Range: 30 - 250
    *   RR-Interval Range: 200ms - 2000ms
*   **Performance:**
    *   Use `drawingGroup()` in SwiftUI for complex animations to offload rendering to Metal.
    *   Respect `BackgroundService` flags for frame rate reduction.
