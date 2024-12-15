import Foundation

class SensorPushSensor: EnvironmentalSensor {
    let id: String
    let name: String
    let type: SensorKit.SensorType = .sensorPush
    private(set) var lastUpdated: Date?
    
    private(set) var currentTemperature: Double?
    private(set) var currentHumidity: Double?
    
    private let device: SensorPushDevice
    private let service = SensorPushService.shared
    
    init(device: SensorPushDevice) {
        self.device = device
        self.id = device.id
        self.name = device.name
    }
    
    func fetchCurrentReading() async throws {
        let samples = try await service.fetchSamples(
            for: id,
            from: Date().addingTimeInterval(-300),
            limit: 1
        )
        
        if let sample = samples.first {
            currentTemperature = sample.temperature
            currentHumidity = sample.humidity
            lastUpdated = sample.time
        }
    }
    
    func fetchHistoricalData(timeRange: TimeRange) async throws -> [SensorKit.SensorReading] {
        let samples = try await service.fetchSamples(
            for: id,
            from: timeRange.startDate(),
            limit: timeRange.limit
        )
        
        return samples.map { sample in
            SensorKit.SensorReading(
                timestamp: sample.time,
                temperature: sample.temperature,
                humidity: sample.humidity
            )
        }
    }
} 