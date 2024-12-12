import SwiftUI
import HomeKit

struct IntegrationsSettingsView: View {
    @AppStorage("sensorPushEnabled") private var sensorPushEnabled = false
    @AppStorage("homeKitEnabled") private var homeKitEnabled = false
    @State private var showingSensorPushLogin = false
    @State private var showingHomeKitSetup = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            Section {
                Toggle("SensorPush Integration", isOn: $sensorPushEnabled)
                    .onChange(of: sensorPushEnabled) { _, newValue in
                        if newValue {
                            showingSensorPushLogin = true
                        }
                    }
                
                if sensorPushEnabled {
                    Button("Manage SensorPush Account") {
                        showingSensorPushLogin = true
                    }
                }
            } footer: {
                Text("Connect your SensorPush sensors to automatically track humidity and temperature.")
            }
            
            Section {
                Toggle("HomeKit Integration", isOn: $homeKitEnabled)
                    .onChange(of: homeKitEnabled) { _, newValue in
                        if newValue {
                            showingHomeKitSetup = true
                        }
                    }
                
                if homeKitEnabled {
                    Button("Manage HomeKit Sensors") {
                        showingHomeKitSetup = true
                    }
                }
            } footer: {
                Text("Use HomeKit compatible temperature and humidity sensors.")
            }
        }
        .navigationTitle("Integrations")
        .sheet(isPresented: $showingSensorPushLogin) {
            NavigationStack {
                SensorPushLoginView { success in
                    if !success {
                        sensorPushEnabled = false
                    }
                }
            }
        }
        .sheet(isPresented: $showingHomeKitSetup) {
            NavigationStack {
                HomeKitSetupView { success in
                    if !success {
                        homeKitEnabled = false
                    }
                }
            }
        }
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
    }
} 