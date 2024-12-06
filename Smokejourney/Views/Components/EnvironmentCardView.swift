import SwiftUI

struct EnvironmentCardView: View {
    let title: String
    let value: String
    let status: EnvironmentStatus
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(status.color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .bold()
                    .foregroundColor(status.color)
                
                Image(systemName: status.icon)
                    .foregroundColor(status.color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(status.color.opacity(0.1))
        .cornerRadius(8)
    }
} 