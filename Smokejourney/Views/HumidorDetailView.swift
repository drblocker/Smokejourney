import SwiftUI
import SwiftData
import os.log
import HomeKit

// MARK: - Main View
struct HumidorDetailView: View {
    // MARK: - Environment & State
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var homeKitManager: HomeKitService
    @StateObject private var viewModel: HumidorEnvironmentViewModel
    
    @State private var showingDeleteAlert = false
    @State private var showingAddCigar = false
    @State private var showingAddSensor = false
    @State private var showingEditHumidor = false
    @State private var searchText = ""
    @State private var currentTemperature: Double?
    @State private var currentHumidity: Double?
    @State private var selectedTempSensorID: String?
    @State private var selectedHumiditySensorID: String?
    
    private let logger = Logger(subsystem: "com.smokejourney", category: "HumidorDetail")
    @Bindable var humidor: Humidor
    
    // MARK: - Initialization
    init(humidor: Humidor) {
        self.humidor = humidor
        _viewModel = StateObject(wrappedValue: HumidorEnvironmentViewModel())
    }
    
    // MARK: - Computed Properties
    private var cigars: [Cigar] {
        humidor.effectiveCigars
    }
    
    private var filteredCigars: [Cigar] {
        guard !searchText.isEmpty else { return cigars }
        return cigars.filter { matches($0, searchTerm: searchText) }
    }
    
    // MARK: - Body
    var body: some View {
        List {
            statusSection
            environmentSection
            cigarsSection
        }
        .searchable(text: $searchText, prompt: "Search cigars")
        .navigationTitle(humidor.name ?? "Unnamed Humidor")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { showingAddCigar = true }) {
                        Label("Add Cigar", systemImage: "plus")
                    }
                    Button(action: { showingEditHumidor = true }) {
                        Label("Edit Humidor", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: { showingDeleteAlert = true }) {
                        Label("Delete Humidor", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddCigar) {
            NavigationStack {
                AddCigarView(humidor: humidor)
            }
        }
        .sheet(isPresented: $showingEditHumidor) {
            NavigationStack {
                EditHumidorView(humidor: humidor)
            }
        }
        .sheet(isPresented: $showingAddSensor) {
            NavigationStack {
                HumidorSensorSelectionView(
                    humidor: humidor,
                    selectedTempSensorID: $selectedTempSensorID,
                    selectedHumiditySensorID: $selectedHumiditySensorID
                )
            }
        }
        .alert("Delete Humidor?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteHumidor()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this humidor? This action cannot be undone.")
        }
        .task {
            await setupEnvironmentMonitoring()
            // Initialize selected sensor IDs from humidor
            selectedTempSensorID = humidor.homeKitTemperatureSensorID
            selectedHumiditySensorID = humidor.homeKitHumiditySensorID
        }
        .onAppear {
            Task {
                await setupCharacteristicNotifications()
            }
        }
    }
    
    // MARK: - View Components
    @ViewBuilder
    private var statusSection: some View {
        Section {
            HumidorStatusView(humidor: humidor)
        }
    }
    
    @ViewBuilder
    private var environmentSection: some View {
        Section("Environment") {
            // Temperature Reading
            if let tempID = humidor.homeKitTemperatureSensorID,
               let sensor = homeKitManager.temperatureSensors.first(where: { $0.uniqueIdentifier.uuidString == tempID }) {
                HStack {
                    Label("Temperature", systemImage: "thermometer")
                    Spacer()
                    if let temp = currentTemperature {
                        let fahrenheit = (temp * 9/5) + 32
                        Text(String(format: "%.1f°F", fahrenheit))
                            .foregroundStyle(sensor.isReachable ? .primary : .secondary)
                    } else {
                        Text("--°F")
                            .foregroundStyle(.secondary)
                    }
                    if !sensor.isReachable {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Humidity Reading
            if let humidityID = humidor.homeKitHumiditySensorID,
               let sensor = homeKitManager.humiditySensors.first(where: { $0.uniqueIdentifier.uuidString == humidityID }) {
                HStack {
                    Label("Humidity", systemImage: "humidity")
                    Spacer()
                    if let humidity = currentHumidity {
                        Text(String(format: "%.1f%%", humidity))
                            .foregroundStyle(sensor.isReachable ? .primary : .secondary)
                    } else {
                        Text("--%")
                            .foregroundStyle(.secondary)
                    }
                    if !sensor.isReachable {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var cigarsSection: some View {
        Section {
            cigarContent()
        } header: {
            if !filteredCigars.isEmpty {
                Text("Cigars (\(filteredCigars.count))")
            }
        }
    }
    
    @ViewBuilder
    private var loadingIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
    
    @ViewBuilder
    private var environmentData: some View {
        HStack {
            temperatureView
            Spacer()
            humidityView
        }
        
        if let error = viewModel.error {
            Text(error)
                .foregroundColor(.red)
                .font(.caption)
        }
    }
    
    @ViewBuilder
    private var temperatureView: some View {
        if let temp = viewModel.temperature {
            Label(String(format: "%.1f°F", temp), systemImage: "thermometer")
                .foregroundColor(viewModel.temperatureStatus.color)
        } else {
            Label("--°F", systemImage: "thermometer")
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var humidityView: some View {
        if let humidity = viewModel.humidity {
            Label(String(format: "%.1f%%", humidity), systemImage: "humidity")
                .foregroundColor(viewModel.humidityStatus.color)
        } else {
            Label("--%", systemImage: "humidity")
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Helper Methods
    private func matches(_ cigar: Cigar, searchTerm: String) -> Bool {
        let searchTerm = searchTerm.lowercased()
        let matchesBrand = cigar.brand?.lowercased().contains(searchTerm) ?? false
        let matchesName = cigar.name?.lowercased().contains(searchTerm) ?? false
        return matchesBrand || matchesName
    }
    
    private func cigarContent() -> some View {
        Group {
            if filteredCigars.isEmpty {
                emptyCigarView()
            } else {
                cigarList()
            }
        }
    }
    
    private func emptyCigarView() -> some View {
        ContentUnavailableView {
            Label("No Cigars", systemImage: "cabinet")
        } description: {
            Text(searchText.isEmpty ? 
                "Add cigars to your humidor" : 
                "No cigars match your search")
        } actions: {
            if searchText.isEmpty {
                Button(action: { showingAddCigar = true }) {
                    Text("Add Cigar")
                }
            }
        }
    }
    
    private func cigarList() -> some View {
        ForEach(filteredCigars) { cigar in
            NavigationLink {
                CigarDetailView(cigar: cigar)
            } label: {
                CigarRowView(cigar: cigar)
            }
        }
        .onDelete(perform: deleteCigars)
    }
    
    // MARK: - Actions
    private func deleteCigars(at offsets: IndexSet) {
        let cigarsToDelete = offsets.map { filteredCigars[$0] }
        
        for cigar in cigarsToDelete {
            logger.debug("Deleting cigar: \(cigar.brand ?? "") - \(cigar.name ?? "")")
            modelContext.delete(cigar)
        }
        
        if humidor.effectiveCigars.isEmpty {
            logger.debug("Humidor is now empty")
        }
    }
    
    private func deleteHumidor() {
        modelContext.delete(humidor)
        dismiss()
    }
    
    private func setupEnvironmentMonitoring() async {
        // Setup existing SensorPush monitoring
        await viewModel.fetchSensors()
        if let sensorId = humidor.sensorId {
            await viewModel.fetchLatestSample(for: sensorId)
            await viewModel.loadHistoricalData(sensorId: sensorId)
        }
        
        // Setup HomeKit monitoring if enabled
        if humidor.homeKitEnabled {
            await refreshHomeKitData()
        }
    }
    
    private func refreshEnvironmentData() async {
        if let sensorId = humidor.sensorId {
            await viewModel.fetchLatestSample(for: sensorId)
        }
    }
    
    private func refreshHomeKitData() async {
        // Get temperature reading
        if let tempID = humidor.homeKitTemperatureSensorID,
           let sensor = homeKitManager.temperatureSensors.first(where: { $0.uniqueIdentifier.uuidString == tempID }) {
            do {
                currentTemperature = try await homeKitManager.readSensorValue(sensor, type: .temperature)
            } catch {
                logger.error("Failed to read temperature: \(error.localizedDescription)")
            }
        }
        
        // Get humidity reading
        if let humidityID = humidor.homeKitHumiditySensorID,
           let sensor = homeKitManager.humiditySensors.first(where: { $0.uniqueIdentifier.uuidString == humidityID }) {
            do {
                currentHumidity = try await homeKitManager.readSensorValue(sensor, type: .humidity)
            } catch {
                logger.error("Failed to read humidity: \(error.localizedDescription)")
            }
        }
    }
    
    // Add HomeKit notification setup
    private func setupCharacteristicNotifications() async {
        // Set up temperature notifications
        if let tempID = humidor.homeKitTemperatureSensorID,
           let sensor = homeKitManager.temperatureSensors.first(where: { $0.uniqueIdentifier.uuidString == tempID }),
           let service = sensor.services.first(where: { $0.serviceType == HMServiceTypeTemperatureSensor }),
           let characteristic = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeCurrentTemperature }) {
            do {
                try await characteristic.enableNotification(true)
                
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("HMCharacteristicValueUpdateNotification"),
                    object: characteristic,
                    queue: .main
                ) { _ in
                    if let value = characteristic.value as? Double {
                        currentTemperature = value
                    }
                }
            } catch {
                print("Failed to enable temperature notifications: \(error.localizedDescription)")
            }
        }
        
        // Set up humidity notifications
        if let humidityID = humidor.homeKitHumiditySensorID,
           let sensor = homeKitManager.humiditySensors.first(where: { $0.uniqueIdentifier.uuidString == humidityID }),
           let service = sensor.services.first(where: { $0.serviceType == HMServiceTypeHumiditySensor }),
           let characteristic = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeCurrentRelativeHumidity }) {
            do {
                try await characteristic.enableNotification(true)
                
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("HMCharacteristicValueUpdateNotification"),
                    object: characteristic,
                    queue: .main
                ) { _ in
                    if let value = characteristic.value as? Double {
                        currentHumidity = value
                    }
                }
            } catch {
                print("Failed to enable humidity notifications: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Supporting Views
private struct HumidorStatusView: View {
    let humidor: Humidor
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Capacity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(humidor.totalCigarCount)/\(humidor.effectiveCapacity)")
                        .font(.title2)
                        .foregroundColor(humidor.isNearCapacity ? .orange : .primary)
                }
                Spacer()
                CapacityIndicator(
                    percentage: humidor.capacityPercentage,
                    isNearCapacity: humidor.isNearCapacity
                )
            }
            
            if humidor.isNearCapacity {
                Label("Limited Space Available", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
}

private struct CigarRowView: View {
    let cigar: Cigar
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(cigar.brand ?? "Unknown Brand") - \(cigar.name ?? "Unknown Name")")
                .font(.headline)
                .lineLimit(1)
            
            HStack {
                Image(systemName: "number.circle.fill")
                    .foregroundColor(.secondary)
                Text("Quantity: \(cigar.totalQuantity)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct CapacityIndicator: View {
    let percentage: Double
    let isNearCapacity: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.gray.opacity(0.2),
                    lineWidth: 8
                )
            
            Circle()
                .trim(from: 0, to: min(CGFloat(percentage), 1.0))
                .stroke(
                    isNearCapacity ? Color.orange : Color.blue,
                    style: StrokeStyle(
                        lineWidth: 8,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: percentage)
            
            Text("\(Int(percentage * 100))%")
                .font(.caption)
                .bold()
        }
        .frame(width: 44, height: 44)
    }
}

