import SwiftUI
import UserNotifications

struct AlertSettingsView: View {
    @AppStorage("tempLowAlert") private var tempLowAlert: Double = 65
    @AppStorage("tempHighAlert") private var tempHighAlert: Double = 72
    @AppStorage("humidityLowAlert") private var humidityLowAlert: Double = 65
    @AppStorage("humidityHighAlert") private var humidityHighAlert: Double = 72
    
    // New alert customization settings
    @AppStorage("alertSound") private var alertSound = "default"
    @AppStorage("alertVibration") private var alertVibration = true
    @AppStorage("alertFrequency") private var alertFrequency: AlertFrequency = .immediate
    @AppStorage("alertQuietHoursEnabled") private var quietHoursEnabled = false
    @AppStorage("alertQuietHoursStart") private var quietHoursStart = 22 // 10 PM
    @AppStorage("alertQuietHoursEnd") private var quietHoursEnd = 7 // 7 AM
    @AppStorage("alertRepeatInterval") private var repeatInterval: TimeInterval = 3600 // 1 hour
    
    private let availableSounds = ["default", "alert", "warning", "critical"]
    
    var body: some View {
        Form {
            // Temperature Alert Settings
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    AlertRangeView(
                        title: "Temperature Range",
                        lowValue: $tempLowAlert,
                        highValue: $tempHighAlert,
                        range: 60...80,
                        unit: "°F",
                        step: 1
                    )
                }
            } header: {
                Text("Temperature Alerts")
            } footer: {
                Text("Recommended temperature range: 65-72°F")
            }
            
            // Humidity Alert Settings
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    AlertRangeView(
                        title: "Humidity Range",
                        lowValue: $humidityLowAlert,
                        highValue: $humidityHighAlert,
                        range: 60...80,
                        unit: "%",
                        step: 1
                    )
                }
            } header: {
                Text("Humidity Alerts")
            } footer: {
                Text("Recommended humidity range: 65-72%")
            }
            
            // Alert Behavior
            Section("Alert Behavior") {
                Picker("Alert Sound", selection: $alertSound) {
                    ForEach(availableSounds, id: \.self) { sound in
                        Text(sound.capitalized).tag(sound)
                    }
                }
                
                Toggle("Vibration", isOn: $alertVibration)
                
                Picker("Alert Frequency", selection: $alertFrequency) {
                    ForEach(AlertFrequency.allCases) { frequency in
                        Text(frequency.description).tag(frequency)
                    }
                }
                
                if alertFrequency == .repeating {
                    Picker("Repeat Interval", selection: $repeatInterval) {
                        Text("15 minutes").tag(TimeInterval(900))
                        Text("30 minutes").tag(TimeInterval(1800))
                        Text("1 hour").tag(TimeInterval(3600))
                        Text("2 hours").tag(TimeInterval(7200))
                        Text("4 hours").tag(TimeInterval(14400))
                    }
                }
            }
            
            // Quiet Hours
            Section("Quiet Hours") {
                Toggle("Enable Quiet Hours", isOn: $quietHoursEnabled)
                
                if quietHoursEnabled {
                    HStack {
                        Text("Start Time")
                        Spacer()
                        Picker("Start Time", selection: $quietHoursStart) {
                            ForEach(0..<24) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    HStack {
                        Text("End Time")
                        Spacer()
                        Picker("End Time", selection: $quietHoursEnd) {
                            ForEach(0..<24) { hour in
                                Text(formatHour(hour)).tag(hour)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            
            // Test Alerts
            Section {
                Button("Test Temperature Alert") {
                    sendTestAlert(type: .temperature)
                }
                
                Button("Test Humidity Alert") {
                    sendTestAlert(type: .humidity)
                }
            } header: {
                Text("Test Alerts")
            } footer: {
                Text("Send a test alert to verify your settings")
            }
        }
        .navigationTitle("Alert Settings")
        .onAppear {
            requestNotificationPermissions()
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        let date = Calendar.current.date(from: DateComponents(hour: hour)) ?? Date()
        return formatter.string(from: date)
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
        }
    }
    
    private func sendTestAlert(type: AlertType) {
        let content = UNMutableNotificationContent()
        content.title = type == .temperature ? "Temperature Alert" : "Humidity Alert"
        content.body = type == .temperature ? 
            "Test temperature alert" : "Test humidity alert"
        content.sound = alertSound == "default" ? .default : .defaultCritical
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Supporting Types
enum AlertFrequency: String, CaseIterable, Identifiable {
    case immediate
    case repeating
    case once
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .immediate: return "Every Time"
        case .repeating: return "Repeating"
        case .once: return "Once Per Condition"
        }
    }
}

enum AlertType {
    case temperature
    case humidity
}

// MARK: - Supporting Views
struct AlertRangeView: View {
    let title: String
    @Binding var lowValue: Double
    @Binding var highValue: Double
    let range: ClosedRange<Double>
    let unit: String
    let step: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            VStack(alignment: .leading) {
                Text("Low Alert")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack {
                    Slider(value: $lowValue, in: range, step: step)
                    Text("\(Int(lowValue))\(unit)")
                        .monospacedDigit()
                        .frame(width: 50)
                }
            }
            
            VStack(alignment: .leading) {
                Text("High Alert")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack {
                    Slider(value: $highValue, in: range, step: step)
                    Text("\(Int(highValue))\(unit)")
                        .monospacedDigit()
                        .frame(width: 50)
                }
            }
        }
    }
} 