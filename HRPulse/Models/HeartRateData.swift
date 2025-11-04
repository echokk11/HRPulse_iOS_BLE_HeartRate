import Foundation

/// 心率数据模型，封装 BPM 和 RR-Interval 数据
struct HeartRateData: Equatable {
    let bpm: Int
    let rrInterval: Double?
    let timestamp: Date
    
    init(bpm: Int, rrInterval: Double? = nil, timestamp: Date = Date()) {
        self.bpm = bpm
        self.rrInterval = rrInterval
        self.timestamp = timestamp
    }
    
    /// 验证心率数据是否有效（30-250 BPM）
    var isValid: Bool {
        return HeartRateData.validateHeartRate(bpm)
    }
    
    /// 验证心率值是否在合理范围内
    static func validateHeartRate(_ bpm: Int) -> Bool {
        return bpm >= 30 && bpm <= 250
    }
    
    /// 验证 RR-Interval 是否在合理范围内（200-2000 ms，对应 30-300 BPM）
    static func validateRRInterval(_ rr: Double) -> Bool {
        return rr >= 200 && rr <= 2000
    }
}
