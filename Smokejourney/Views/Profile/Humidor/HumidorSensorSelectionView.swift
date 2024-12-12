import SwiftUI

struct HumidorSensorSelectionView: View {
    @EnvironmentObject private var homeKitManager: HomeKitService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var humidor: Humidor?
    @Binding var selectedTempSensorID: String?
    @Binding var selectedHumiditySensorID: String?
    
    var body: some View {
        List {
            Section("Temperature Sensors") {
                if homeKitManager.temperatureSensors.isEmpty {
                    Text("No temperature sensors found")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(homeKitManager.temperatureSensors, id: \.uniqueIdentifier) { accessory in
                        AccessoryRow(accessory: accessory)
                            .contentShape(Rectangle())
                            .overlay {
                                if accessory.uniqueIdentifier.uuidString == selectedTempSensorID {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                            .onTapGesture {
                                Task {
                                    await homeKitManager.selectSensor(accessory, type: .temperature)
                                    selectedTempSensorID = accessory.uniqueIdentifier.uuidString
                                    if let humidor = humidor {
                                        humidor.homeKitTemperatureSensorID = selectedTempSensorID
                                        try? modelContext.save()
                                    }
                                }
                            }
                    }
                }
            }
            
            Section("Humidity Sensors") {
                if homeKitManager.humiditySensors.isEmpty {
                    Text("No humidity sensors found")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(homeKitManager.humiditySensors, id: \.uniqueIdentifier) { accessory in
                        AccessoryRow(accessory: accessory)
                            .contentShape(Rectangle())
                            .overlay {
                                if accessory.uniqueIdentifier.uuidString == selectedHumiditySensorID {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                            .onTapGesture {
                                Task {
                                    await homeKitManager.selectSensor(accessory, type: .humidity)
                                    selectedHumiditySensorID = accessory.uniqueIdentifier.uuidString
                                    if let humidor = humidor {
                                        humidor.homeKitHumiditySensorID = selectedHumiditySensorID
                                        try? modelContext.save()
                                    }
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle("Select Sensors")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if humidor == nil {
                // Only show Done button when creating new humidor
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
} 