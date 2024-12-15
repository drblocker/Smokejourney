import SwiftUI

struct SensorPushListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sensorPushService: SensorPushService
    let onSelect: (SensorPushDevice) -> Void
    
    var body: some View {
        List(sensorPushService.sensors, id: \.id) { device in
            Button {
                onSelect(device)
                dismiss()
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(device.name)
                            .foregroundStyle(.primary)
                        Text("Temperature & Humidity")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Select Sensor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SensorPushListView { _ in }
            .environmentObject(SensorPushService.shared)
    }
} 