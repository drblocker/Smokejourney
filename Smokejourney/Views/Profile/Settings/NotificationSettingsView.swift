import SwiftUI
import UserNotifications

public struct NotificationSettingsView: View {
    @AppStorage("humidityAlerts") private var humidityAlerts = true
    @AppStorage("temperatureAlerts") private var temperatureAlerts = true
    @AppStorage("stockAlerts") private var stockAlerts = true
    
    public init() {}
    
    public var body: some View {
        List {
            Section {
                Toggle("Humidity Alerts", isOn: $humidityAlerts)
                Toggle("Temperature Alerts", isOn: $temperatureAlerts)
                Toggle("Low Stock Alerts", isOn: $stockAlerts)
            } footer: {
                Text("Choose which types of notifications you'd like to receive.")
            }
            
            Section {
                NavigationLink {
                    NotificationThresholdsView()
                } label: {
                    Label("Alert Thresholds", systemImage: "slider.horizontal.3")
                }
            } footer: {
                Text("Configure when alerts should be triggered.")
            }
        }
        .navigationTitle("Notification Settings")
    }
}

private struct NotificationThresholdsView: View {
    @AppStorage("humidityLowThreshold") private var humidityLowThreshold = 62.0
    @AppStorage("humidityHighThreshold") private var humidityHighThreshold = 72.0
    @AppStorage("temperatureLowThreshold") private var temperatureLowThreshold = 65.0
    @AppStorage("temperatureHighThreshold") private var temperatureHighThreshold = 75.0
    @AppStorage("stockThreshold") private var stockThreshold = 5
    
    var body: some View {
        List {
            Section("Humidity") {
                VStack {
                    Text("Low Threshold: \(Int(humidityLowThreshold))%")
                    Slider(value: $humidityLowThreshold, in: 55...65, step: 1)
                }
                VStack {
                    Text("High Threshold: \(Int(humidityHighThreshold))%")
                    Slider(value: $humidityHighThreshold, in: 70...80, step: 1)
                }
            }
            
            Section("Temperature") {
                VStack {
                    Text("Low Threshold: \(Int(temperatureLowThreshold))°F")
                    Slider(value: $temperatureLowThreshold, in: 60...70, step: 1)
                }
                VStack {
                    Text("High Threshold: \(Int(temperatureHighThreshold))°F")
                    Slider(value: $temperatureHighThreshold, in: 70...80, step: 1)
                }
            }
            
            Section("Stock") {
                Stepper("Alert when stock below: \(stockThreshold)", value: $stockThreshold, in: 1...20)
            }
        }
        .navigationTitle("Alert Thresholds")
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
} 