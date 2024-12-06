import SwiftUI
import SwiftData

// MARK: - Models
struct DiscoveredSensor: Identifiable {
    let id: String
    let name: String
    let type: SensorType
}

// MARK: - Components
struct SensorDiscoveryRow: View {
    let sensor: DiscoveredSensor
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(sensor.name)
                    .font(.headline)
                Text(sensor.type.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
    }
} 