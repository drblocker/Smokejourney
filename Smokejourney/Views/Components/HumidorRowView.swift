import SwiftUI

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