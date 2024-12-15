import SwiftUI
import SwiftData
import os.log
import HomeKit

// MARK: - Main View
struct HumidorDetailView: View {
    // MARK: - Environment & State
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var homeKitService: HomeKitService
    @StateObject private var climateViewModel: ClimateViewModel
    
    @State private var showingDeleteAlert = false
    @State private var showingAddCigar = false
    @State private var showingAddSensor = false
    @State private var showingEditHumidor = false
    @State private var searchText = ""
    
    private let logger = Logger(subsystem: "com.smokejourney", category: "HumidorDetail")
    @Bindable var humidor: Humidor
    
    // MARK: - Initialization
    init(humidor: Humidor, modelContext: ModelContext) {
        self.humidor = humidor
        _climateViewModel = StateObject(wrappedValue: ClimateViewModel(modelContext: modelContext))
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
                HumidorEditView(humidor: humidor)
            }
        }
        .sheet(isPresented: $showingAddSensor) {
            NavigationStack {
                SensorSelectionSheet { sensor in
                    humidor.climateSensor = sensor
                    try? modelContext.save()
                }
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
            if let sensor = humidor.climateSensor {
                CurrentConditionsCard(
                    viewModel: climateViewModel,
                    showTitle: false
                )
                EnvironmentChartsSection(viewModel: climateViewModel)
                StabilityMetricsView(viewModel: climateViewModel)
            } else {
                Button(action: { showingAddSensor = true }) {
                    Label("Add Sensor", systemImage: "plus")
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
        if let sensor = humidor.climateSensor {
            await climateViewModel.loadSensorData(for: sensor)
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

