import SwiftUI

struct HumidorAlertSettingsView: View {
    @AppStorage("tempLowAlert") private var tempLowAlert: Double = 65
    @AppStorage("tempHighAlert") private var tempHighAlert: Double = 72
    @AppStorage("humidityLowAlert") private var humidityLowAlert: Double = 65
    @AppStorage("humidityHighAlert") private var humidityHighAlert: Double = 72
    
    var body: some View {
        Form {
            Section {
                VStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Low Temperature Alert")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack {
                            Slider(value: $tempLowAlert, in: 60...70, step: 1)
                            Text("\(Int(tempLowAlert))°F")
                                .monospacedDigit()
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("High Temperature Alert")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack {
                            Slider(value: $tempHighAlert, in: 70...80, step: 1)
                            Text("\(Int(tempHighAlert))°F")
                                .monospacedDigit()
                        }
                    }
                }
            } header: {
                Text("Temperature Alerts")
            } footer: {
                Text("Recommended temperature range: 65-72°F")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                VStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Low Humidity Alert")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack {
                            Slider(value: $humidityLowAlert, in: 60...70, step: 1)
                            Text("\(Int(humidityLowAlert))%")
                                .monospacedDigit()
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("High Humidity Alert")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack {
                            Slider(value: $humidityHighAlert, in: 70...80, step: 1)
                            Text("\(Int(humidityHighAlert))%")
                                .monospacedDigit()
                        }
                    }
                }
            } header: {
                Text("Humidity Alerts")
            } footer: {
                Text("Recommended humidity range: 65-72%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Current Settings", systemImage: "bell.badge.fill")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Temperature Range:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(Int(tempLowAlert))°F - \(Int(tempHighAlert))°F")
                            .font(.body)
                            .monospacedDigit()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Humidity Range:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(Int(humidityLowAlert))% - \(Int(humidityHighAlert))%")
                            .font(.body)
                            .monospacedDigit()
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Summary")
            }
        }
        .navigationTitle("Alert Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        HumidorAlertSettingsView()
    }
} 