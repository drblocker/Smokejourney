import SwiftUI
import SwiftData

struct AddHumidorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var sensorViewModel = HumidorEnvironmentViewModel()
    
    @State private var name = ""
    @State private var capacity = 25
    @State private var location = ""
    @State private var selectedSensorId: String?
    @State private var showSensorSelection = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    Stepper("Capacity: \(capacity)", value: $capacity, in: 1...1000)
                    TextField("Location", text: $location)
                }
                
                Section("Environment Sensor") {
                    if let sensorId = selectedSensorId,
                       let sensor = sensorViewModel.sensors.first(where: { $0.id == sensorId }) {
                        HStack {
                            Text(sensor.name)
                            Spacer()
                            Button("Change") {
                                showSensorSelection = true
                            }
                        }
                    } else {
                        Button("Select Sensor") {
                            showSensorSelection = true
                        }
                    }
                }
            }
            .navigationTitle("Add Humidor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let humidor = Humidor(name: name, capacity: capacity, location: location)
                        humidor.sensorId = selectedSensorId
                        modelContext.insert(humidor)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showSensorSelection) {
                NavigationStack {
                    SensorSelectionView(selectedSensorId: $selectedSensorId)
                }
            }
            .task {
                await sensorViewModel.fetchSensors()
            }
        }
    }
} 