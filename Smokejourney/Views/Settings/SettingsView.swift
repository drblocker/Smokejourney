import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("sensorPushAuthenticated") private var isSensorPushAuthenticated = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Toggle(isOn: $isDarkMode) {
                        Label("Dark Mode", systemImage: "moon.fill")
                    }
                }
                
                Section("Environmental Monitoring") {
                    NavigationLink(destination: SensorPushSettingsView()) {
                        HStack {
                            Label("SensorPush", systemImage: "sensor")
                            Spacer()
                            if isSensorPushAuthenticated {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                Section("HomeKit Integration") {
                    NavigationLink(destination: HomeKitSettingsView()) {
                        Label("HomeKit Settings", systemImage: "house")
                    }
                }
                
                Section {
                    NavigationLink(destination: AboutView()) {
                        Label("About", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
} 