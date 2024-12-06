import SwiftUI
import SwiftData

struct HumidorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var humidors: [Humidor]
    @State private var showAddHumidor = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(humidors) { humidor in
                    NavigationLink(destination: HumidorDetailView(humidor: humidor)) {
                        HumidorRowView(humidor: humidor)
                    }
                }
                .onDelete(perform: deleteHumidors)
            }
            .navigationTitle("Humidors")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddHumidor = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddHumidor) {
                NavigationStack {
                    AddHumidorView()
                }
            }
            .overlay {
                if humidors.isEmpty {
                    ContentUnavailableView {
                        Label("No Humidors", systemImage: "cabinet")
                    } description: {
                        Text("Add a humidor to start tracking your cigars")
                    } actions: {
                        Button(action: { showAddHumidor = true }) {
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