import SwiftUI
import SwiftData

struct HumidorDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var humidor: Humidor
    @State private var searchText = ""
    @State private var showAddCigar = false
    @State private var showEditHumidor = false
    @State private var showDeleteAlert = false
    @State private var showEditCigar = false
    @State private var cigarToEdit: Cigar?
    @State private var showEnvironmentHistory = false
    @State private var showAlertSettings = false
    @State private var showSensorManagement = false
    @State private var showEnvironmentReport = false
    
    private var filteredCigars: [Cigar] {
        guard !searchText.isEmpty else {
            return humidor.effectiveCigars
        }
        
        return humidor.effectiveCigars.filter { cigar in
            let searchTerms = searchText.lowercased()
            let brandMatch = cigar.brand?.lowercased().contains(searchTerms) ?? false
            let nameMatch = cigar.name?.lowercased().contains(searchTerms) ?? false
            return brandMatch || nameMatch
        }
    }
    
    private var capacityStatusView: some View {
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
                CapacityWarning()
            }
        }
    }
    
    var body: some View {
        List {
            // Humidor Status Section
            Section {
                capacityStatusView
            }
            
            // Cigars Section
            Section {
                CigarListContent(
                    cigars: filteredCigars,
                    searchText: searchText,
                    onAdd: { showAddCigar = true },
                    onDelete: deleteCigar,
                    onEdit: { cigarToEdit = $0 }
                )
            } header: {
                if !filteredCigars.isEmpty {
                    Text("Cigars (\(filteredCigars.count))")
                }
            }
        }
        .navigationTitle(humidor.effectiveName)
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer,
            prompt: "Search cigars..."
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HumidorMenuButton(
                    onAddCigar: { showAddCigar = true },
                    onEditHumidor: { showEditHumidor = true },
                    onDeleteHumidor: { showDeleteAlert = true }
                )
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
        .sheet(item: $cigarToEdit) { cigar in
            EditCigarView(cigar: cigar)
        }
        .alert("Delete Humidor", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteHumidor()
            }
        } message: {
            Text("Are you sure you want to delete this humidor? This action cannot be undone.")
        }
    }
    
    private func deleteCigar(_ cigar: Cigar) {
        withAnimation {
            modelContext.delete(cigar)
        }
    }
    
    private func deleteHumidor() {
        modelContext.delete(humidor)
        dismiss()
    }
}

// MARK: - Supporting Views
struct CapacityIndicator: View {
    let percentage: Double
    let isNearCapacity: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
            Circle()
                .trim(from: 0, to: percentage)
                .stroke(
                    isNearCapacity ? Color.orange : Color.blue,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 44, height: 44)
    }
}

struct CapacityWarning: View {
    var body: some View {
        Label(
            "Limited Space Available",
            systemImage: "exclamationmark.triangle.fill"
        )
        .font(.subheadline)
        .foregroundColor(.orange)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

struct HumidorMenuButton: View {
    let onAddCigar: () -> Void
    let onEditHumidor: () -> Void
    let onDeleteHumidor: () -> Void
    
    var body: some View {
        Menu {
            Button(action: onAddCigar) {
                Label("Add Cigar", systemImage: "plus")
            }
            
            Button(action: onEditHumidor) {
                Label("Edit Humidor", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: onDeleteHumidor) {
                Label("Delete Humidor", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}

struct CigarListContent: View {
    let cigars: [Cigar]
    let searchText: String
    let onAdd: () -> Void
    let onDelete: (Cigar) -> Void
    let onEdit: (Cigar) -> Void
    
    var body: some View {
        if cigars.isEmpty {
            ContentUnavailableView {
                Label("No Cigars", systemImage: "cabinet")
            } description: {
                Text(searchText.isEmpty ? 
                    "Add cigars to your humidor" : 
                    "No cigars match your search")
            } actions: {
                if searchText.isEmpty {
                    Button(action: onAdd) {
                        Text("Add Cigar")
                    }
                }
            }
        } else {
            ForEach(cigars) { cigar in
                NavigationLink(destination: CigarDetailView(cigar: cigar)) {
                    CigarRowView(cigar: cigar)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        onDelete(cigar)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        onEdit(cigar)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
    }
}

struct CigarRowView: View {
    let cigar: Cigar
    
    var body: some View {
        HStack {
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
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}