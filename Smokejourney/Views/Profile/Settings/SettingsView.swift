import SwiftUI
import SwiftData
import UserNotifications

// Add explicit module name if needed
typealias NotificationSettings = NotificationSettingsView

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authManager = AuthenticationManager.shared
    @AppStorage("temperatureUnit") private var temperatureUnit = "fahrenheit"
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("theme") private var theme = "system"
    
    var body: some View {
        List {
            // Temperature Settings
            Section {
                Picker("Temperature Unit", selection: $temperatureUnit) {
                    Text("Fahrenheit").tag("fahrenheit")
                    Text("Celsius").tag("celsius")
                }
            } header: {
                Text("Temperature")
            } footer: {
                Text("Choose your preferred temperature unit for display throughout the app.")
            }
            
            // Notification Settings
            Section {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { _, newValue in
                        Task {
                            if newValue {
                                await requestNotificationPermission()
                            }
                        }
                    }
                
                if notificationsEnabled {
                    NavigationLink {
                        NotificationSettings()
                    } label: {
                        Label("Notification Settings", systemImage: "bell.badge")
                    }
                }
            } header: {
                Text("Notifications")
            }
            
            // Appearance Settings
            Section {
                Picker("Theme", selection: $theme) {
                    Label("System", systemImage: "iphone").tag("system")
                    Label("Light", systemImage: "sun.max").tag("light")
                    Label("Dark", systemImage: "moon").tag("dark")
                }
            } header: {
                Text("Appearance")
            }
            
            // Integrations Settings
            Section {
                NavigationLink {
                    IntegrationsSettingsView()
                } label: {
                    Label("Integrations", systemImage: "link")
                }
            } header: {
                Text("Integrations")
            } footer: {
                Text("Connect with SensorPush and HomeKit")
            }
        }
        .navigationTitle("Settings")
    }
    
    private func requestNotificationPermission() async {
        do {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            
            guard settings.authorizationStatus == .authorized else {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .badge, .sound])
                
                if !granted {
                    notificationsEnabled = false
                }
                return
            }
        } catch {
            notificationsEnabled = false
            print("Error requesting notification permission: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .modelContainer(for: User.self, inMemory: true)
    }
} 