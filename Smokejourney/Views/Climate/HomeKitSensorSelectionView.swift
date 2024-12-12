import SwiftUI
import HomeKit

struct HomeKitSensorSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var homeKitManager: HomeKitService
    let onSelect: (String?) -> Void
    var selectedTempSensorID: Binding<String?>? = nil
    var selectedHumiditySensorID: Binding<String?>? = nil
    
    var body: some View {
        List {
            Section("Temperature Sensors") {
                ForEach(homeKitManager.temperatureSensors, id: \.uniqueIdentifier) { sensor in
                    Button {
                        if let binding = selectedTempSensorID {
                            binding.wrappedValue = sensor.uniqueIdentifier.uuidString
                            try? modelContext.save()
                        }
                        onSelect(sensor.uniqueIdentifier.uuidString)
                    } label: {
                        HStack {
                            Text(sensor.name)
                            Spacer()
                            if sensor.isReachable {
                                Image(systemName: "wifi")
                                    .foregroundColor(.green)
                            }
                            if sensor.uniqueIdentifier.uuidString == selectedTempSensorID?.wrappedValue {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            
            Section("Humidity Sensors") {
                ForEach(homeKitManager.humiditySensors, id: \.uniqueIdentifier) { sensor in
                    Button {
                        if let binding = selectedHumiditySensorID {
                            binding.wrappedValue = sensor.uniqueIdentifier.uuidString
                            try? modelContext.save()
                        }
                        onSelect(sensor.uniqueIdentifier.uuidString)
                    } label: {
                        HStack {
                            Text(sensor.name)
                            Spacer()
                            if sensor.isReachable {
                                Image(systemName: "wifi")
                                    .foregroundColor(.green)
                            }
                            if sensor.uniqueIdentifier.uuidString == selectedHumiditySensorID?.wrappedValue {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Sensor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onSelect(nil)
                }
            }
        }
    }
} 