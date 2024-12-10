import SwiftUI
import SwiftData
import os.log

struct HumidorListView: View {
    @Environment(\.modelContext) var modelContext
    @Query private var humidors: [Humidor]
    @State private var showAddHumidor = false
    private let logger = Logger(subsystem: "com.smokejourney", category: "HumidorListView")
    
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
        .onAppear {
            logger.debug("HumidorListView appeared, humidor count: \(humidors.count)")
        }
        .onChange(of: humidors) { oldValue, newValue in
            logger.debug("Humidors changed: Old count: \(oldValue.count), New count: \(newValue.count)")
        }
    }
    
    private func deleteHumidors(_ indexSet: IndexSet) {
        for index in indexSet {
            deleteHumidor(humidors[index])
        }
    }
    
    private func deleteHumidor(_ humidor: Humidor) {
        Task {
            do {
                try await modelContext.deleteWithCloudKit(humidor)
            } catch {
                print("Error deleting humidor: \(error)")
            }
        }
    }
} 