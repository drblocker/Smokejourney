import SwiftUI
import SwiftData
import os.log

struct HumidorListView: View {
    @Environment(\.modelContext) var modelContext
    @Query private var humidors: [Humidor]
    private let logger = Logger(subsystem: "com.smokejourney", category: "HumidorListView")
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(humidors) { humidor in
                    NavigationLink(destination: HumidorDetailView(humidor: humidor)) {
                        HumidorRowView(humidor: humidor)
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