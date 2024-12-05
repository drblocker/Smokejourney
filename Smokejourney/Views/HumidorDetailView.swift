import SwiftUI
import SwiftData
import os.log

struct HumidorDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var humidor: Humidor
    
    // State
    @State private var searchText = ""
    @State private var showAddCigar = false
    @State private var showEditHumidor = false
    @State private var showDeleteAlert = false
    
    private let logger = Logger(subsystem: "com.smokejourney", category: "HumidorDetailView")
    
    // MARK: - Computed Properties
    private var filteredCigars: [Cigar] {
        let cigars = humidor.cigars ?? []
        guard !searchText.isEmpty else { return cigars }
        
        return cigars.filter { cigar in
            let searchTerms = searchText.lowercased()
            return cigar.brand?.lowercased().contains(searchTerms) ?? false ||
                   cigar.name?.lowercased().contains(searchTerms) ?? false
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HumidorStatusView(humidor: humidor)
                }
                
                Section {
                    if filteredCigars.isEmpty {
                        ContentUnavailableView {
                            Label("No Cigars", systemImage: "cabinet")
                        } description: {
                            Text(searchText.isEmpty ? 
                                "Add cigars to your humidor" : 
                                "No cigars match your search")
                        } actions: {
                            if searchText.isEmpty {
                                Button(action: { showAddCigar = true }) {
                                    Text("Add Cigar")
                                }
                            }
                        }
                    } else {
                        ForEach(filteredCigars) { cigar in
                            NavigationLink {
                                CigarDetailView(cigar: cigar)
                            } label: {
                                CigarRowView(cigar: cigar)
                            }
                        }
                        .onDelete(perform: deleteCigars)
                    }
                } header: {
                    if !filteredCigars.isEmpty {
                        Text("Cigars (\(filteredCigars.count))")
                    }
                }
            }
            .navigationTitle(humidor.effectiveName)
            .searchable(text: $searchText, prompt: "Search cigars...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { showAddCigar = true }) {
                            Label("Add Cigar", systemImage: "plus")
                        }
                        
                        Button(action: { showEditHumidor = true }) {
                            Label("Edit Humidor", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: { showDeleteAlert = true }) {
                            Label("Delete Humidor", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showAddCigar) {
                NavigationStack {
                    AddCigarView(humidor: humidor)
                }
            }
            .sheet(isPresented: $showEditHumidor) {
                NavigationStack {
                    EditHumidorView(humidor: humidor)
                }
            }
            .alert("Delete Humidor", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive, action: deleteHumidor)
            } message: {
                Text("Are you sure you want to delete this humidor? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Actions
    private func deleteCigars(at offsets: IndexSet) {
        // Get cigars to delete before modifying the array
        let cigarsToDelete = offsets.map { filteredCigars[$0] }
        
        // Delete each cigar
        for cigar in cigarsToDelete {
            logger.debug("Deleting cigar: \(cigar.brand ?? "") - \(cigar.name ?? "")")
            modelContext.delete(cigar)
        }
        
        // Update humidor's cigars array if needed
        if humidor.cigars?.isEmpty == true {
            humidor.cigars = []
            logger.debug("Humidor is now empty")
        }
    }
    
    private func deleteHumidor() {
        modelContext.delete(humidor)
        dismiss()
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

