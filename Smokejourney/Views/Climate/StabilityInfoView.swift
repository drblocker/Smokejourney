import SwiftUI

struct StabilityInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Stability metrics show how consistent your humidor's environment has been over the selected time period.")
                        .font(.callout)
                }
                
                Section("Stability Score") {
                    Text("The circular gauges show a score from 0-1, where:")
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• 1.0 = Perfect stability")
                        Text("• 0.8+ = Excellent stability")
                        Text("• 0.6-0.8 = Good stability")
                        Text("• Below 0.6 = Needs attention")
                    }
                    .font(.callout)
                }
                
                Section("Variance") {
                    Text("The ± values show how much your readings typically vary from the average. Lower numbers indicate better stability.")
                        .font(.callout)
                }
            }
            .navigationTitle("About Stability")
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
} 