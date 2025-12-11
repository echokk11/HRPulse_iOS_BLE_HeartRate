import Foundation
import HealthKit

class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var error: Error?
    
    enum ReadAuthorizationState {
        case notAvailable
        case notDetermined
        case denied
        case authorized
    }
    
    private let quantityIdentifiers: [HKQuantityTypeIdentifier] = [
        .bodyMass,
        .bodyFatPercentage,
        .heartRate,
        .stepCount
    ]
    
    private var readTypes: Set<HKObjectType> {
        Set(quantityIdentifiers.compactMap { HKObjectType.quantityType(forIdentifier: $0) })
    }
    
    private var shareTypes: Set<HKSampleType> {
        Set(quantityIdentifiers.compactMap { HKObjectType.quantityType(forIdentifier: $0) as HKSampleType? })
    }
    
    private var authorizationTypes: Set<HKObjectType> {
        readTypes.union(Set(shareTypes.map { $0 as HKObjectType }))
    }
    
    private init() {}
    
    /// 检查授权请求状态
    func checkAuthorizationStatus(completion: @escaping (HKAuthorizationRequestStatus, Error?) -> Void) {
        healthStore.getRequestStatusForAuthorization(toShare: shareTypes, read: readTypes) { status, error in
            DispatchQueue.main.async {
                completion(status, error)
            }
        }
    }
    
    /// 请求 HealthKit 授权
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            let error = NSError(domain: "com.hrpulse.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "当前设备不支持 HealthKit"])
            completion(false, error)
            return
        }
        
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                self?.error = error
                completion(success, error)
            }
        }
    }
    
    /// 读取当前健康数据读取权限状态
    func currentReadAuthorizationState() -> ReadAuthorizationState {
        guard HKHealthStore.isHealthDataAvailable() else {
            return .notAvailable
        }
        
        let statuses = authorizationTypes.map { healthStore.authorizationStatus(for: $0) }
        
        if statuses.contains(.notDetermined) {
            return .notDetermined
        }
        
        if statuses.contains(where: { $0 == .sharingDenied }) {
            return .denied
        }
        
        return .authorized
    }
    
    /// 获取最新的体重数据（单位：kg）
    func fetchLatestWeight(completion: @escaping (Double?, Error?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion(nil, nil)
            return
        }
        
        fetchMostRecentSample(for: type) { sample, error in
            guard let sample = sample as? HKQuantitySample else {
                completion(nil, error)
                return
            }
            
            let weightInKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            completion(weightInKg, nil)
        }
    }
    
    /// 获取最新的体脂率数据（单位：百分比，0-100）
    func fetchLatestBodyFatPercentage(completion: @escaping (Double?, Error?) -> Void) {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else {
            completion(nil, nil)
            return
        }
        
        fetchMostRecentSample(for: type) { sample, error in
            guard let sample = sample as? HKQuantitySample else {
                completion(nil, error)
                return
            }
            
            // HealthKit 返回的是 0-1 的小数，我们需要转换为百分比
            let percentage = sample.quantity.doubleValue(for: .percent()) * 100
            completion(percentage, nil)
        }
    }
    
    /// 通用方法：获取某种类型的最新一条样本
    private func fetchMostRecentSample(for sampleType: HKSampleType, completion: @escaping (HKSample?, Error?) -> Void) {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let limit = 1
        
        let query = HKSampleQuery(sampleType: sampleType, predicate: nil, limit: limit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            DispatchQueue.main.async {
                guard let samples = samples, let mostRecentSample = samples.first else {
                    completion(nil, error)
                    return
                }
                
                completion(mostRecentSample, nil)
            }
        }
        
        healthStore.execute(query)
    }
}
