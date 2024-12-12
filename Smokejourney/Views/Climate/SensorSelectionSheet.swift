import SwiftUI
import SwiftData

struct SensorSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sensorPushManager: SensorPushService
    @EnvironmentObject private var homeKitManager: HomeKitService
    @State private var sensorType: SensorType = .sensorPush
    @State private var showingSensorList = false
    @State private var showingAuth = false
    let onSelect: (String?, ClimateSensor.SensorType) -> Void
    
    var body: some View {
        List {
            Section {
                Picker("Sensor Type", selection: $sensorType) {
                    Text("SensorPush").tag(SensorType.sensorPush)
                    Text("HomeKit").tag(SensorType.homeKit)
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets())
                .padding()
            }
            
            Section {
                Button {
                    if sensorType == .sensorPush && !sensorPushManager.isAuthorized {
                        showingAuth = true
                    } else if sensorType == .homeKit && !homeKitManager.isAuthorized {
                        showingAuth = true
                    } else {
                        showingSensorList = true
                    }
                } label: {
                    HStack {
                        Label(
                            sensorType == .sensorPush ? "Select SensorPush Device" : "Select HomeKit Device",
                            systemImage: sensorType == .sensorPush ? "sensor.fill" : "homekit"
                        )
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
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
        .sheet(isPresented: $showingSensorList) {
            NavigationStack {
                if sensorType == .sensorPush {
                    SensorPushSelectionView { sensorId in
                        onSelect(sensorId, .sensorPush)
                        dismiss()
                    }
                } else {
                    HomeKitSensorSelectionView { sensorId in
                        onSelect(sensorId, .homeKit)
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAuth) {
            NavigationStack {
                if sensorType == .sensorPush {
                    SensorPushLoginView { success in
                        if success {
                            showingAuth = false
                            showingSensorList = true
                        }
                    }
                } else {
                    HomeKitSetupView { success in
                        if success {
                            showingAuth = false
                            showingSensorList = true
                        }
                    }
                }
            }
        }
    }
    
    enum SensorType {
        case sensorPush
        case homeKit
    }
}

#Preview {
    NavigationStack {
        SensorSelectionSheet { _, _ in }
            .environmentObject(SensorPushService())
            .environmentObject(HomeKitService())
    }
}