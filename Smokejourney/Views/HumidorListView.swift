import SwiftUI
import SwiftData

struct HumidorListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var humidors: [Humidor]
    @StateObject private var syncMonitor: SyncMonitor
    
    @State private var searchText = ""
    @State private var showAddHumidor = false
    
    init(modelContext: ModelContext) {
        _syncMonitor = StateObject(wrappedValue: SyncMonitor(modelContext: modelContext))
    }
    
    var filteredHumidors: [Humidor] {
        if searchText.isEmpty {
            return humidors
        }
        return humidors.filter { humidor in
            humidor.effectiveName.localizedCaseInsensitiveContains(searchText) ||
            (humidor.location?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredHumidors) { humidor in
                    NavigationLink(destination: HumidorDetailView(humidor: humidor)) {
                        HumidorRowView(humidor: humidor)
                    }
                }
                .onDelete(perform: deleteHumidor)
            }
            .navigationTitle("Humidors")
            .searchable(text: $searchText, prompt: "Search humidors...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddHumidor.toggle() }) {
                        Label("Add Humidor", systemImage: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                
                ToolbarItem(placement: .status) {
                    SyncStatusView(syncMonitor: syncMonitor)
                }
            }
            .sheet(isPresented: $showAddHumidor) {
                AddHumidorView()
            }
        }
    }
    
    private func deleteHumidor(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredHumidors[$0] }.forEach(modelContext.delete)
        }
    }
}

struct HumidorRowView: View {
    let humidor: Humidor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(humidor.effectiveName)
                .font(.headline)
            
            HStack {
                Text("\(humidor.totalCigarCount)/\(humidor.effectiveCapacity) cigars")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let location = humidor.location {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
} 