import SwiftUI
import SwiftData

struct EnvironmentSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [EnvironmentSettings]
    @State private var minTemp: Double = 65.0
    @State private var maxTemp: Double = 72.0
    @State private var minHumidity: Double = 62.0
    @State private var maxHumidity: Double = 75.0
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Min Temperature")
                    Spacer()
                    TextField("Min", value: $minTemp, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("°F")
                }
                
                HStack {
                    Text("Max Temperature")
                    Spacer()
                    TextField("Max", value: $maxTemp, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("°F")
                }
            } header: {
                Text("Temperature")
            } footer: {
                Text("Recommended temperature range for cigars is between 65-72°F")
            }
            
            Section {
                HStack {
                    Text("Min Humidity")
                    Spacer()
                    TextField("Min", value: $minHumidity, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("%")
                }
                
                HStack {
                    Text("Max Humidity")
                    Spacer()
                    TextField("Max", value: $maxHumidity, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("%")
                }
            } header: {
                Text("Humidity")
            } footer: {
                Text("Recommended humidity range for cigars is between 62-75%")
            }
        }
        .navigationTitle("Environment Settings")
        .onAppear {
            if let existingSettings = settings.first {
                minTemp = existingSettings.minTemperature
                maxTemp = existingSettings.maxTemperature
                minHumidity = existingSettings.minHumidity
                maxHumidity = existingSettings.maxHumidity
            } else {
                let defaultSettings = EnvironmentSettings(
                    maxTemperature: maxTemp,
                    minTemperature: minTemp,
                    maxHumidity: maxHumidity,
                    minHumidity: minHumidity
                )
                modelContext.insert(defaultSettings)
            }
        }
        .onChange(of: minTemp) { updateSettings() }
        .onChange(of: maxTemp) { updateSettings() }
        .onChange(of: minHumidity) { updateSettings() }
        .onChange(of: maxHumidity) { updateSettings() }
    }
    
    private func updateSettings() {
        if let existingSettings = settings.first {
            existingSettings.minTemperature = minTemp
            existingSettings.maxTemperature = maxTemp
            existingSettings.minHumidity = minHumidity
            existingSettings.maxHumidity = maxHumidity
        }
    }
}

#Preview {
    EnvironmentSettingsView()
        .modelContainer(for: EnvironmentSettings.self, inMemory: true)
} 