import SwiftUI
import HomeKit

struct HomeKitSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var homeKitService: HomeKitService
    @State private var isAuthorized = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let onComplete: (Bool) -> Void
    
    var body: some View {
        List {
            Section {
                if homeKitService.isAuthorized {
                    Button("Add Accessory") {
                        Task {
                            await addAccessory()
                        }
                    }
                } else {
                    Button("Request Access") {
                        Task {
                            await requestAccess()
                        }
                    }
                }
            } header: {
                Text("HomeKit Access")
            } footer: {
                Text("HomeKit access is required to monitor temperature and humidity sensors.")
            }
            
            if let home = homeKitService.home {
                Section {
                    ForEach(home.accessories, id: \.uniqueIdentifier) { accessory in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(accessory.name)
                                    .font(.headline)
                                if let room = accessory.room?.name {
                                    Text(room)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if accessory.isReachable {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                } header: {
                    Text("Accessories")
                }
            }
        }
        .navigationTitle("HomeKit Setup")
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func requestAccess() async {
        do {
            try await homeKitService.requestAuthorization()
            isAuthorized = true
        } catch {
            showingError = true
            errorMessage = error.localizedDescription
            onComplete(false)
        }
    }
    
    private func addAccessory() async {
        do {
            try await homeKitService.addAccessory()
            onComplete(true)
            dismiss()
        } catch {
            showingError = true
            errorMessage = error.localizedDescription
            onComplete(false)
        }
    }
}