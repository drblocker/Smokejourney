import SwiftUI
import SwiftData

struct SensorSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ClimateViewModel
    
    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: ClimateViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        HomeKitSensorListView { accessory in
                            let climateSensor = ClimateSensor(
                                id: accessory.uniqueIdentifier.uuidString,
                                name: accessory.name,
                                type: .homeKit
                            )
                            modelContext.insert(climateSensor)
                            Task {
                                await viewModel.loadSensorData(for: climateSensor)
                            }
                            dismiss()
                        }
                    } label: {
                        Label("HomeKit Sensors", systemImage: "homekit")
                    }
                    
                    NavigationLink {
                        SensorPushAuthView()
                    } label: {
                        Label("SensorPush Sensors", systemImage: "sensor.fill")
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
        }
    }
} 