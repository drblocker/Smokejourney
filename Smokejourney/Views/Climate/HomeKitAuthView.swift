import SwiftUI
import HomeKit

struct HomeKitAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var homeKitService: HomeKitService
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "homekit")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                Text("HomeKit Access Required")
                    .font(.headline)
                
                Text("This app needs access to your HomeKit accessories to monitor temperature and humidity.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                Button {
                    Task {
                        await requestAccess()
                    }
                } label: {
                    Text("Allow Access")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.top)
                .disabled(isLoading)
            }
            .padding()
            .navigationTitle("HomeKit Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                }
            } message: {
                if let error = error {
                    Text(error)
                }
            }
        }
    }
    
    private func requestAccess() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await homeKitService.requestAuthorization()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
} 