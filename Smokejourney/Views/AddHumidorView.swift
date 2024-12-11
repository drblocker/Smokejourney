import SwiftUI
import SwiftData

struct AddHumidorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var homeKitManager: HomeKitService
    @EnvironmentObject private var sensorPushManager: SensorPushService
    
    @State private var name = ""
    @State private var capacity = ""
    @State private var location = ""
    @State private var showSensorSelection = false
    @State private var selectedSensorType: SensorType?
    @State private var homeKitEnabled = false
    @State private var selectedTempSensorID: String?
    @State private var selectedHumiditySensorID: String?
    @State private var selectedSensorPushID: String?
    
    private var capacityInt: Int {
        return Int(capacity) ?? 25
    }
    
    enum SensorType {
        case homeKit
        case sensorPush
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Capacity", text: $capacity)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode) // Ensures numeric keyboard on all devices
                    TextField("Location", text: $location, 
                            prompt: Text("e.g., Office, Living Room"))
                }
                
                Section("Environment Monitoring") {
                    if sensorPushManager.isAuthorized {
                        sensorPushSelectionRow
                    }
                    
                    if homeKitManager.isAuthorized {
                        homeKitSelectionRows
                    }
                    
                    if !sensorPushManager.isAuthorized && !homeKitManager.isAuthorized {
                        Text("Configure SensorPush or HomeKit in Settings to enable environment monitoring")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("New Humidor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveHumidor() }
                        .disabled(name.isEmpty || capacity.isEmpty || 
                                Int(capacity) == nil || Int(capacity)! <= 0)
                }
            }
            .sheet(isPresented: $showSensorSelection) {
                NavigationStack {
                    if selectedSensorType == .homeKit {
                        HumidorSensorSelectionView(
                            humidor: nil,
                            selectedTempSensorID: $selectedTempSensorID,
                            selectedHumiditySensorID: $selectedHumiditySensorID
                        )
                    } else if selectedSensorType == .sensorPush {
                        SensorPushSelectionView(selectedSensorID: $selectedSensorPushID)
                    }
                }
            }
        }
    }
    
    private var sensorPushSelectionRow: some View {
        HStack {
            Label("SensorPush", systemImage: "sensor")
            Spacer()
            if let sensorID = selectedSensorPushID,
               let sensor = sensorPushManager.sensors.first(where: { $0.id == sensorID }) {
                Text(sensor.displayName)
                    .foregroundStyle(.secondary)
            } else {
                Button("Select") {
                    selectedSensorType = .sensorPush
                    showSensorSelection = true
                }
            }
        }
    }
    
    private var homeKitSelectionRows: some View {
        Group {
            // Temperature Sensor Selection
            HStack {
                Label("HomeKit Temperature", systemImage: "thermometer")
                Spacer()
                if let sensorID = selectedTempSensorID,
                   let sensor = homeKitManager.temperatureSensors.first(where: { $0.uniqueIdentifier.uuidString == sensorID }) {
                    Text(sensor.name)
                        .foregroundStyle(.secondary)
                } else {
                    Button("Select") {
                        selectedSensorType = .homeKit
                        showSensorSelection = true
                    }
                }
            }
            
            // Humidity Sensor Selection
            HStack {
                Label("HomeKit Humidity", systemImage: "humidity")
                Spacer()
                if let sensorID = selectedHumiditySensorID,
                   let sensor = homeKitManager.humiditySensors.first(where: { $0.uniqueIdentifier.uuidString == sensorID }) {
                    Text(sensor.name)
                        .foregroundStyle(.secondary)
                } else {
                    Button("Select") {
                        selectedSensorType = .homeKit
                        showSensorSelection = true
                    }
                }
            }
        }
    }
    
    private func saveHumidor() {
        guard let capacityNum = Int(capacity), capacityNum > 0 else { return }
        
        let humidor = Humidor(
            name: name,
            capacity: capacityNum,
            description: nil,
            location: location.isEmpty ? nil : location
        )
        
        // Set HomeKit sensors if selected
        if let tempID = selectedTempSensorID {
            humidor.homeKitEnabled = true
            humidor.homeKitTemperatureSensorID = tempID
        }
        if let humidityID = selectedHumiditySensorID {
            humidor.homeKitEnabled = true
            humidor.homeKitHumiditySensorID = humidityID
        }
        
        // Set SensorPush sensor if selected
        if let sensorPushID = selectedSensorPushID {
            humidor.sensorId = sensorPushID
        }
        
        modelContext.insert(humidor)
        dismiss()
    }
} 