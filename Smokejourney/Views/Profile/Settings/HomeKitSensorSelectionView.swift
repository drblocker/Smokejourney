import SwiftUI

struct HomeKitSensorSelectionView: View {
    @EnvironmentObject private var homeKitManager: HomeKitService
    @Environment(\.dismiss) private var dismiss
    
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
                            .onTapGesture {
                                Task {
                                    // Handle sensor selection
                                    await homeKitManager.selectSensor(accessory, type: .temperature)
                                    dismiss()
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
                            .onTapGesture {
                                Task {
                                    // Handle sensor selection
                                    await homeKitManager.selectSensor(accessory, type: .humidity)
                                    dismiss()
                                }
                            }
                    }
                }
            }
            
            if !homeKitManager.isAuthorized || homeKitManager.currentHome == nil {
                Section {
                    Button("Setup HomeKit") {
                        // Show HomeKit setup
                    }
                } footer: {
                    Text("HomeKit must be configured before you can select sensors.")
                }
            }
            
            Section {
                Button("Add Accessory") {
                    Task {
                        if let home = homeKitManager.currentHome {
                            try? await homeKitManager.addAccessory(name: "New Sensor", type: .temperature)
                        }
                    }
                }
            } footer: {
                Text("Add a new HomeKit accessory to your home.")
            }
        }
        .navigationTitle("HomeKit Sensors")
        .task {
            await homeKitManager.refreshAccessories()
        }
    }
} 