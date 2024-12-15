import SwiftUI

struct AlertsView: View {
    @Environment(\.dismiss) private var dismiss
    let alerts: [EnvironmentalAlert]
    
    var body: some View {
        List(alerts) { alert in
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.headline)
                Text(alert.message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Alerts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
} 