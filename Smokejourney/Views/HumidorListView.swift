import SwiftUI
import SwiftData

struct HumidorListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var humidors: [Humidor]
    @State private var showAddHumidor = false
    
    var body: some View {
        Group {
            if humidors.isEmpty {
                ContentUnavailableView {
                    Label("No Humidors", systemImage: "humidor.fill")
                } description: {
                    Text("Add a humidor to start tracking your collection")
                } actions: {
                    addButton
                }
            } else {
                humidorList
            }
        }
        .navigationTitle("Humidors")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                addButton
            }
        }
        .sheet(isPresented: $showAddHumidor) {
            AddHumidorView()
        }
    }
    
    private var addButton: some View {
        Button(action: { showAddHumidor = true }) {
            Label("Add Humidor", systemImage: "plus")
        }
    }
    
    private var humidorList: some View {
        List {
            ForEach(humidors) { humidor in
                NavigationLink(value: humidor) {
                    HumidorRow(humidor: humidor)
                }
            }
            .onDelete(perform: deleteHumidors)
        }
    }
    
    private func deleteHumidors(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(humidors[index])
        }
    }
}

#Preview {
    NavigationStack {
        HumidorListView()
    }
    .modelContainer(for: Humidor.self, inMemory: true)
}