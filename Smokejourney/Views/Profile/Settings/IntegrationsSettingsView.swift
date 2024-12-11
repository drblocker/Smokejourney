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
                            requestHomeKitAccess()
                        }
                    }
                
                if homeKitEnabled {
                    NavigationLink("Select Sensors") {
                        HomeKitSensorSelectionView()
                    }
                    
                    Button("Configure HomeKit") {
                        showingHomeKitSetup = true
                    }
                }
            } footer: {
                Text("Add your humidors to HomeKit for Siri control and automation.")
            }
        }
        .navigationTitle("Integrations")
        .sheet(isPresented: $showingSensorPushLogin) {
            NavigationStack {
                SensorPushLoginView { success in
                    if !success {
                        sensorPushEnabled = false
                    }
                    showingSensorPushLogin = false
                }
            }
        }
        .sheet(isPresented: $showingHomeKitSetup) {
            NavigationStack {
                HomeKitSetupView(onComplete: { success in
                    if !success {
                        homeKitEnabled = false
                    }
                    showingHomeKitSetup = false
                })
                .environmentObject(HomeKitService.shared)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func requestHomeKitAccess() {
        let manager = HMHomeManager()
        // HomeKit authorization is handled automatically when accessing the first time
        if manager.homes.isEmpty {
            showingHomeKitSetup = true
        }
    }
}

#Preview {
    NavigationStack {
        IntegrationsSettingsView()
    }
} 