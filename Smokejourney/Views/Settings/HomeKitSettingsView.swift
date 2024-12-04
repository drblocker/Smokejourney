import SwiftUI
import HomeKit

struct HomeKitSettingsView: View {
    @StateObject private var homeKit = HomeKitService.shared
    @State private var showAuthAlert = false
    @State private var showAddAccessory = false
    @State private var showHomeSetup = false
    
    private var setupMessage: String {
        if FileManager.default.ubiquityIdentityToken == nil {
            return "Please sign in to iCloud in Settings before setting up HomeKit."
        } else if homeKit.authorizationStatus == 5 as UInt {
            return "HomeKit authorization is pending. Please wait a moment and try again."
        } else if homeKit.currentHome == nil {
            return "Please open Settings > Home to set up a HomeKit home. After creating a home, return to this app to add your sensors."
        } else if !homeKit.isAuthorized {
            return "Please enable HomeKit access in Settings to continue."
        } else {
            return "Ready to set up sensors."
        }
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("HomeKit Status")
                    Spacer()
                    if homeKit.isAuthorized {
                        Label("Connected", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Label("Not Connected", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                
                if let home = homeKit.currentHome {
                    Text("Current Home: \(home.name)")
                }
            }
            
            if homeKit.isAuthorized {
                Section("Temperature Sensors") {
                    ForEach(homeKit.temperatureSensors, id: \.uniqueIdentifier) { sensor in
                        HStack {
                            Label(sensor.name, systemImage: "thermometer")
                            Spacer()
                            if sensor.isReachable {
                                Image(systemName: "wifi")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    Button(action: { 
                        showAddAccessory = true 
                    }) {
                        Label("Add Temperature Sensor", systemImage: "plus")
                    }
                }
                
                Section("Humidity Sensors") {
                    ForEach(homeKit.humiditySensors, id: \.uniqueIdentifier) { sensor in
                        HStack {
                            Label(sensor.name, systemImage: "humidity")
                            Spacer()
                            if sensor.isReachable {
                                Image(systemName: "wifi")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    Button(action: { 
                        showAddAccessory = true 
                    }) {
                        Label("Add Humidity Sensor", systemImage: "plus")
                    }
                }
            } else {
                Section {
                    Button("Set Up HomeKit") {
                        showHomeSetup = true
                    }
                } footer: {
                    Text("You need to set up a HomeKit home in the Settings app before adding sensors.")
                }
            }
        }
        .navigationTitle("HomeKit Settings")
        .alert("HomeKit Setup Required", isPresented: $showHomeSetup) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(setupMessage)
        }
        .alert("HomeKit Error", isPresented: $showAuthAlert) {
            Button("OK", role: .cancel) { }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Please enable HomeKit access in Settings to continue.")
        }
        .sheet(isPresented: $showAddAccessory) {
            AddHomeKitAccessoryView()
        }
    }
}

struct AddHomeKitAccessoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var homeKit = HomeKitService.shared
    @State private var name = ""
    @State private var selectedType: HomeKitService.SensorType = .temperature
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Accessory Name", text: $name)
                    
                    Picker("Sensor Type", selection: $selectedType) {
                        Text("Temperature").tag(HomeKitService.SensorType.temperature)
                        Text("Humidity").tag(HomeKitService.SensorType.humidity)
                    }
                }
            }
            .navigationTitle("Add HomeKit Accessory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addAccessory()
                    }
                    .disabled(name.isEmpty || isLoading)
                }
            }
            .alert("Error", isPresented: $showError, presenting: error) { _ in
                Button("OK", role: .cancel) { }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }
    
    private func addAccessory() {
        isLoading = true
        
        Task {
            do {
                try await homeKit.setupAccessory(name: name, sensorType: selectedType)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    showError = true
                    isLoading = false
                }
            }
        }
    }
} 