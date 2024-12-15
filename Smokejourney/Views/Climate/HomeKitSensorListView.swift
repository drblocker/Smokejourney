import SwiftUI
import HomeKit

struct HomeKitSensorListView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var homeKitService: HomeKitService
    let onSelect: (HMAccessory) -> Void
    
    var body: some View {
        List {
            ForEach(homeKitService.temperatureSensors, id: \.uniqueIdentifier) { accessory in
                Button {
                    onSelect(accessory)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(accessory.name)
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
        HomeKitSensorListView { _ in }
            .environmentObject(HomeKitService.shared)
    }
} 