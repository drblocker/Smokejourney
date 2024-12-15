import SwiftUI

struct IntegrationsSettingsView: View {
    @EnvironmentObject private var homeKitService: HomeKitService
    @EnvironmentObject private var sensorPushService: SensorPushService
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            Section {
                NavigationLink {
                    HomeKitSetupView { success in
                        if !success {
                            showingError = true
                            errorMessage = "Failed to setup HomeKit"
                        }
                    }
                } label: {
                    HStack {
                        Label("HomeKit", systemImage: "homekit")
                        Spacer()
                        if homeKitService.isAuthorized {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            } header: {
                Text("HomeKit")
            } footer: {
                Text("Connect to HomeKit accessories to monitor temperature and humidity.")
            }
            
            Section {
                NavigationLink {
                    SensorPushSettingsView()
                } label: {
                    HStack {
                        Label("SensorPush", systemImage: "sensor.fill")
                        Spacer()
                        if sensorPushService.isAuthorized {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            } header: {
                Text("SensorPush")
            } footer: {
                Text("Connect to your SensorPush account to monitor temperature and humidity.")
            }
        }
        .navigationTitle("Integrations")
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

#Preview {
    NavigationStack {
        IntegrationsSettingsView()
            .environmentObject(HomeKitService.shared)
            .environmentObject(SensorPushService.shared)
    }
}