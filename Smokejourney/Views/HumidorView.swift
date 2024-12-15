import SwiftUI
import SwiftData

struct HumidorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var humidors: [Humidor]
    @State private var showingAddHumidor = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(humidors) { humidor in
                    NavigationLink(destination: HumidorDetailView(humidor: humidor, modelContext: modelContext)) {
                        HumidorRowView(humidor: humidor)
                    }
                }
                .onDelete(perform: deleteHumidors)
            }
            .navigationTitle("Humidors")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddHumidor = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHumidor) {
                NavigationStack {
                    HumidorCreateView()
                }
            }
            .overlay {
                if humidors.isEmpty {
                    ContentUnavailableView {
                        Label("No Humidors", systemImage: "cabinet")
                    } description: {
                        Text("Add a humidor to start tracking your cigars")
                    } actions: {
                        Button(action: { showingAddHumidor = true }) {
                            Text("Add Humidor")
                        }
                    }
                }
            }
        }
    }
    
    private func deleteHumidors(_ indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(humidors[index])
        }
    }
} 