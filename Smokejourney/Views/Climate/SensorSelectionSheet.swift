import SwiftUI
import SwiftData
import HomeKit

struct SensorSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var homeKitService: HomeKitService
    @EnvironmentObject private var sensorPushService: SensorPushService
    
    let onSelect: (ClimateSensor) -> Void
    
    @State private var sensorType: SensorType = .homeKit
    @State private var showingHomeKitAuth = false
    @State private var showingSensorPushAuth = false
    @State private var showingSensorList = false
    
    var body: some View {
        List {
            Section {
                Picker("Sensor Type", selection: $sensorType) {
                    Text("HomeKit").tag(SensorType.homeKit)
                    Text("SensorPush").tag(SensorType.sensorPush)
                }
                .pickerStyle(.segmented)
            }
            
            if sensorType == .homeKit {
                HomeKitSection(
                    isAuthorized: homeKitService.isAuthorized,
                    showingAuth: $showingHomeKitAuth,
                    showingSensorList: $showingSensorList
                )
            } else {
                SensorPushSection(
                    isAuthorized: sensorPushService.isAuthorized,
                    showingAuth: $showingSensorPushAuth,
                    showingSensorList: $showingSensorList
                )
            }
        }
        .navigationTitle("Add Sensor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingHomeKitAuth) {
            HomeKitAuthView()
        }
        .sheet(isPresented: $showingSensorPushAuth) {
            SensorPushAuthView()
        }
        .sheet(isPresented: $showingSensorList) {
            if sensorType == .homeKit {
                HomeKitSensorListView { accessory in
                    saveSensor(HomeKitSensor(accessory: accessory))
                    dismiss()
                }
            } else {
                SensorPushListView { device in
                    saveSensor(SensorPushSensor(device: device))
                    dismiss()
                }
            }
        }
    }
    
    private func saveSensor(_ sensor: any EnvironmentalSensor) {
        let climateSensor = ClimateSensor(
            id: sensor.id,
            name: sensor.name,
            type: sensor.type
        )
        modelContext.insert(climateSensor)
        onSelect(climateSensor)
    }
}

// MARK: - Supporting Views
private struct SensorPushSection: View {
    let isAuthorized: Bool
    @Binding var showingAuth: Bool
    @Binding var showingSensorList: Bool
    
    var body: some View {
        Section {
            Button {
                if isAuthorized {
                    showingSensorList = true
                } else {
                    showingAuth = true
                }
            } label: {
                HStack {
                    Label("SensorPush Devices", systemImage: "sensor.fill")
                    Spacer()
                    if isAuthorized {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Sign In Required")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } footer: {
            if !isAuthorized {
                Text("Sign in to your SensorPush account to access your sensors.")
            }
        }
    }
}

private struct HomeKitSection: View {
    let isAuthorized: Bool
    @Binding var showingAuth: Bool
    @Binding var showingSensorList: Bool
    
    var body: some View {
        Section {
            Button {
                if isAuthorized {
                    showingSensorList = true
                } else {
                    showingAuth = true
                }
            } label: {
                HStack {
                    Label("HomeKit Devices", systemImage: "homekit")
                    Spacer()
                    if isAuthorized {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Setup Required")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } footer: {
            if !isAuthorized {
                Text("Allow access to your HomeKit accessories to monitor temperature and humidity.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        SensorSelectionSheet { sensor in
            print("Selected sensor: \(sensor.name)")
        }
        .environmentObject(HomeKitService.shared)
        .environmentObject(SensorPushService.shared)
    }
}