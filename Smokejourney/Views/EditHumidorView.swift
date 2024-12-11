import SwiftUI
import SwiftData

struct EditHumidorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var humidor: Humidor
    @StateObject private var sensorViewModel = HumidorEnvironmentViewModel()
    @EnvironmentObject private var homeKitManager: HomeKitService
    
    @State private var name: String
    @State private var capacityString: String
    @State private var location: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showSensorSelection = false
    @State private var selectedSensorType: SensorType?
    @State private var selectedTempSensorID: String?
    @State private var selectedHumiditySensorID: String?
    
    enum SensorType {
        case homeKit
        case sensorPush
    }
    
    // Computed property to handle capacity validation
    private var capacity: Int {
        return Int(capacityString) ?? humidor.effectiveCapacity
    }
    
    private var isValidCapacity: Bool {
        guard let value = Int(capacityString) else { return false }
        return value >= humidor.effectiveCigars.count && value <= 1000
    }
    
    init(humidor: Humidor) {
        self.humidor = humidor
        _name = State(initialValue: humidor.effectiveName)
        _capacityString = State(initialValue: String(humidor.effectiveCapacity))
        _location = State(initialValue: humidor.location ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Humidor Details") {
                    TextField("Name", text: $name)
                    TextField("Capacity", text: $capacityString)
                        .keyboardType(.numberPad)
                    TextField("Location", text: $location)
                }
                
                Section("Environment Monitoring") {
                    // SensorPush
                    if let sensorId = humidor.sensorId,
                       let sensor = sensorViewModel.sensors.first(where: { $0.id == sensorId }) {
                        Text(sensor.displayName)
                            .foregroundStyle(.secondary)
                    } else {
                        Button("Select SensorPush") {
                            selectedSensorType = .sensorPush
                            showSensorSelection = true
                        }
                    }
                    
                    // HomeKit
                    if homeKitManager.isAuthorized {
                        Toggle("Enable HomeKit", isOn: $humidor.homeKitEnabled)
                        
                        if humidor.homeKitEnabled {
                            // Temperature Sensor Selection
                            HStack {
                                Text("Temperature Sensor")
                                Spacer()
                                if let sensorID = humidor.homeKitTemperatureSensorID,
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
                            
                            if let _ = humidor.homeKitTemperatureSensorID {
                                Button(role: .destructive) {
                                    humidor.homeKitTemperatureSensorID = nil
                                } label: {
                                    Label("Remove Temperature Sensor", systemImage: "trash")
                                }
                            }
                            
                            // Humidity Sensor Selection
                            HStack {
                                Text("Humidity Sensor")
                                Spacer()
                                if let sensorID = humidor.homeKitHumiditySensorID,
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
                            
                            if let _ = humidor.homeKitHumiditySensorID {
                                Button(role: .destructive) {
                                    humidor.homeKitHumiditySensorID = nil
                                } label: {
                                    Label("Remove Humidity Sensor", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Humidor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if validateAndSave() {
                            dismiss()
                        }
                    }
                }
            }
            .alert("Invalid Input", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showSensorSelection) {
                NavigationStack {
                    if selectedSensorType == .sensorPush {
                        SensorSelectionView(selectedSensorId: $humidor.sensorId)
                    } else {
                        HumidorSensorSelectionView(
                            humidor: humidor,
                            selectedTempSensorID: $selectedTempSensorID,
                            selectedHumiditySensorID: $selectedHumiditySensorID
                        )
                    }
                }
            }
            .onChange(of: selectedTempSensorID) {
                if selectedTempSensorID != nil {
                    humidor.homeKitEnabled = true
                    humidor.homeKitTemperatureSensorID = selectedTempSensorID
                }
            }
            .onChange(of: selectedHumiditySensorID) {
                if selectedHumiditySensorID != nil {
                    humidor.homeKitEnabled = true
                    humidor.homeKitHumiditySensorID = selectedHumiditySensorID
                }
            }
            .task {
                await sensorViewModel.fetchSensors()
            }
        }
    }
    
    private func validateAndSave() -> Bool {
        guard let capacityValue = Int(capacityString) else {
            alertMessage = "Please enter a valid number for capacity"
            showAlert = true
            return false
        }
        
        guard capacityValue >= humidor.effectiveCigars.count else {
            alertMessage = "Capacity cannot be less than current number of cigars"
            showAlert = true
            return false
        }
        
        guard capacityValue <= 1000 else {
            alertMessage = "Capacity must be 1000 or less"
            showAlert = true
            return false
        }
        
        humidor.name = name
        humidor.capacity = capacityValue
        humidor.location = location.isEmpty ? nil : location
        
        return true
    }
} 