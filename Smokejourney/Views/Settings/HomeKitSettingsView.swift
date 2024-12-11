import SwiftUI
import HomeKit

struct HomeKitSettingsView: View {
    @StateObject private var homeKit = HomeKitService.shared
    @State private var showAuthAlert = false
    @State private var showAddAccessory = false
    @State private var error: Error?
    @State private var showError = false
    
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
                
                if !homeKit.isAuthorized {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            } footer: {
                Text(setupMessage)
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
                    
                    Button(action: { showAddAccessory = true }) {
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
                    
                    Button(action: { showAddAccessory = true }) {
                        Label("Add Humidity Sensor", systemImage: "plus")
                    }
                }
            }
        }
        .navigationTitle("HomeKit Settings")
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
        .task {
            await homeKit.checkAuthorization()
        }
    }
    
    private var setupMessage: String {
        if FileManager.default.ubiquityIdentityToken == nil {
            return "Please sign in to iCloud in Settings to use HomeKit."
        }
        
        switch homeKit.authorizationStatus {
        case .authorized:
            return homeKit.currentHome == nil ? 
                "Please set up a HomeKit home in the Home app first." :
                "HomeKit is properly configured."
        case .determined:
            return "Checking HomeKit authorization..."
        case .restricted:
            return "HomeKit access is restricted on this device."
        default:
            return "Please enable HomeKit access in Settings to continue."
        }
    }
}

struct AddHomeKitAccessoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var homeKit = HomeKitService.shared
    @State private var name = ""
    @State private var selectedType = HomeKitService.SensorType.temperature
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
                try await homeKit.addAccessory(name: name, type: selectedType)
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