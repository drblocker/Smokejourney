import SwiftUI

struct HumidorRow: View {
    let humidor: Humidor
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(humidor.effectiveName)
                .font(.headline)
            
            HStack {
                Label("\(humidor.totalCigarCount)/\(humidor.effectiveCapacity)", systemImage: "cigar")
                    .foregroundStyle(.secondary)
                
                if let sensor = humidor.climateSensor,
                   let temperature = sensor.currentTemperature,
                   let humidity = sensor.currentHumidity {
                    Spacer()
                    Text(String(format: "%.1f°F", temperature))
                    Text(String(format: "%.1f%%", humidity))
                }
            }
            .font(.caption)
        }
    }
}

#Preview {
    let humidor = Humidor(name: "Test Humidor", capacity: 25)
    return HumidorRow(humidor: humidor)
        .modelContainer(for: Humidor.self, inMemory: true)
} 