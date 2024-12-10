import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @State private var isNotificationsEnabled = false
    @State private var showingSettingsAlert = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Notifications", isOn: $isNotificationsEnabled)
                    .onChange(of: isNotificationsEnabled) { isEnabled in
                        if isEnabled {
                            requestNotificationPermission()
                        }
                    }
            } header: {
                Text("Notification Settings")
            } footer: {
                Text("Enable notifications to receive alerts about temperature and humidity changes in your humidors.")
            }
            
            if isNotificationsEnabled {
                Section("Alert Types") {
                    NavigationLink("Temperature Alerts") {
                        TemperatureAlertSettingsView()
                    }
                    
                    NavigationLink("Humidity Alerts") {
                        HumidityAlertSettingsView()
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .onAppear {
            checkNotificationStatus()
        }
        .alert("Enable Notifications", isPresented: $showingSettingsAlert) {
            Button("Cancel", role: .cancel) {
                isNotificationsEnabled = false
            }
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Please enable notifications in Settings to receive alerts about your humidors.")
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                isNotificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    isNotificationsEnabled = true
                } else {
                    isNotificationsEnabled = false
                    showingSettingsAlert = true
                }
            }
        }
    }
}

struct TemperatureAlertSettingsView: View {
    @AppStorage("tempAlertEnabled") private var isEnabled = true
    @AppStorage("tempAlertThreshold") private var threshold = 5.0
    
    var body: some View {
        Form {
            Section {
                Toggle("Temperature Alerts", isOn: $isEnabled)
                if isEnabled {
                    Stepper("Threshold: ±\(Int(threshold))°F", value: $threshold, in: 1...10)
                }
            } footer: {
                Text("You'll receive alerts when temperature changes exceed the threshold.")
            }
        }
        .navigationTitle("Temperature Alerts")
    }
}

struct HumidityAlertSettingsView: View {
    @AppStorage("humidityAlertEnabled") private var isEnabled = true
    @AppStorage("humidityAlertThreshold") private var threshold = 5.0
    
    var body: some View {
        Form {
            Section {
                Toggle("Humidity Alerts", isOn: $isEnabled)
                if isEnabled {
                    Stepper("Threshold: ±\(Int(threshold))%", value: $threshold, in: 1...10)
                }
            } footer: {
                Text("You'll receive alerts when humidity changes exceed the threshold.")
            }
        }
        .navigationTitle("Humidity Alerts")
    }
}