import SwiftUI
import HomeKit

struct HomeKitSetupView: View {
    @StateObject private var homeKitManager = HomeKitManager.shared
    @Bindable var humidor: Humidor
    
    @State private var showingAuthorizationAlert = false
    @State private var authorizationError: String?
    @State private var showingAddRoomSheet = false
    @State private var newRoomName = ""
    @State private var showingRoomError = false
    @State private var roomError: String?
    @State private var showingSensorPairingSheet = false
    @State private var showingAutomationError = false
    @State private var automationError: String?
    @State private var isPairing = false
    @State private var showPairingSheet = false
    @State private var pairingError: String?
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable HomeKit", isOn: $humidor.homeKitEnabled)
                    .onChange(of: humidor.homeKitEnabled) { isEnabled in
                        if isEnabled {
                            requestAuthorization()
                        }
                    }
                
                if humidor.homeKitEnabled {
                    if homeKitManager.isAuthorized {
                        roomSelectionSection
                        sensorSection
                        automationSection
                    } else {
                        Text("HomeKit not authorized")
                            .foregroundColor(.red)
                    }
                }
            } header: {
                Text("HomeKit Integration")
            } footer: {
                Text("Enable HomeKit to monitor temperature and humidity with HomeKit sensors")
            }
        }
        .alert("HomeKit Authorization Failed", isPresented: $showingAuthorizationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authorizationError ?? "Unknown error")
        }
        .alert("Room Error", isPresented: $showingRoomError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(roomError ?? "Unknown error")
        }
        .sheet(isPresented: $showingAddRoomSheet) {
            NavigationStack {
                Form {
                    TextField("Room Name", text: $newRoomName)
                }
                .navigationTitle("Add Room")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingAddRoomSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            createRoom()
                        }
                        .disabled(newRoomName.isEmpty)
                    }
                }
            }
            .presentationDetents([.height(200)])
        }
        .sheet(isPresented: $showPairingSheet) {
            SensorPairingView(humidor: humidor)
        }
    }
    
    private var roomSelectionSection: some View {
        Group {
            if homeKitManager.availableRooms.isEmpty {
                Text("No rooms available")
                    .foregroundColor(.secondary)
            } else {
                Picker("Room", selection: .init(
                    get: { homeKitManager.selectedRoom },
                    set: { room in
                        if let room = room {
                            selectRoom(room)
                        }
                    }
                )) {
                    Text("Select Room").tag(nil as HMRoom?)
                    ForEach(homeKitManager.availableRooms, id: \.uniqueIdentifier) { room in
                        Text(room.name).tag(room as HMRoom?)
                    }
                }
            }
            
            Button(action: { showingAddRoomSheet = true }) {
                Label("Add Room", systemImage: "plus.circle")
            }
            
            if let selectedRoom = homeKitManager.selectedRoom {
                let accessories = homeKitManager.getRoomAccessories(selectedRoom)
                if !accessories.isEmpty {
                    Section("Room Accessories") {
                        ForEach(accessories, id: \.uniqueIdentifier) { accessory in
                            HStack {
                                Image(systemName: "sensor.fill")
                                Text(accessory.name)
                                Spacer()
                                if accessory.isReachable {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var sensorSection: some View {
        Section("Sensors") {
            if let room = homeKitManager.selectedRoom {
                Button(action: {
                    showPairingSheet = true
                }) {
                    Label("Add Sensor", systemImage: "plus.circle")
                }
                
                if isPairing {
                    ProgressView("Searching for sensors...")
                }
                
                let accessories = homeKitManager.getRoomAccessories(room)
                ForEach(accessories, id: \.uniqueIdentifier) { accessory in
                    SensorRow(accessory: accessory)
                }
            } else {
                Text("Select a room to add sensors")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showPairingSheet) {
            SensorPairingView(humidor: humidor)
        }
    }
    
    private var automationSection: some View {
        Section("Automations") {
            if let room = homeKitManager.selectedRoom,
               humidor.homeKitTemperatureSensorID != nil || humidor.homeKitHumiditySensorID != nil {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Target Temperature")
                        Spacer()
                        Text("\(humidor.targetTemperature?.formatted() ?? "70")°F")
                    }
                    
                    HStack {
                        Text("Target Humidity")
                        Spacer()
                        Text("\(humidor.targetHumidity?.formatted() ?? "65")%")
                    }
                    
                    Button(action: configureAutomations) {
                        Label("Configure Automations", systemImage: "gear")
                    }
                }
            } else {
                Text("Add sensors to configure automations")
                    .foregroundColor(.secondary)
            }
        }
        .alert("Automation Error", isPresented: $showingAutomationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(automationError ?? "Unknown error")
        }
    }
    
    private func selectRoom(_ room: HMRoom) {
        Task {
            do {
                try await homeKitManager.selectRoom(room, for: humidor)
            } catch {
                await MainActor.run {
                    roomError = error.localizedDescription
                    showingRoomError = true
                }
            }
        }
    }
    
    private func createRoom() {
        Task {
            do {
                let room = try await homeKitManager.createRoom(name: newRoomName)
                await MainActor.run {
                    showingAddRoomSheet = false
                    newRoomName = ""
                    selectRoom(room)
                }
            } catch {
                await MainActor.run {
                    roomError = error.localizedDescription
                    showingRoomError = true
                    showingAddRoomSheet = false
                }
            }
        }
    }
    
    private func requestAuthorization() {
        Task {
            do {
                try await homeKitManager.requestAuthorization()
            } catch {
                await MainActor.run {
                    authorizationError = error.localizedDescription
                    showingAuthorizationAlert = true
                    humidor.homeKitEnabled = false
                }
            }
        }
    }
    
    private func configureAutomations() {
        Task {
            do {
                try await homeKitManager.configureSensorAutomation(for: humidor)
            } catch {
                await MainActor.run {
                    automationError = error.localizedDescription
                    showingAutomationError = true
                }
            }
        }
    }
    
    private func startPairing() {
        Task {
            do {
                try await homeKitManager.startSensorPairing()
            } catch {
                pairingError = error.localizedDescription
            }
        }
    }
}

struct SensorPairingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var homeKitManager = HomeKitManager.shared
    @Bindable var humidor: Humidor
    
    var body: some View {
        NavigationView {
            VStack {
                // Pairing content
            }
            .navigationTitle("Add Sensor")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
        .onDisappear {
            Task {
                await homeKitManager.stopSensorPairing()
            }
        }
    }
}

struct SensorRow: View {
    let accessory: HMAccessory
    
    var body: some View {
        HStack {
            Image(systemName: "sensor.fill")
            VStack(alignment: .leading) {
                Text(accessory.name)
                Text(accessory.category.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if accessory.isReachable {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
    }
} 