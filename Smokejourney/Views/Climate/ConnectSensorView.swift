import SwiftUI

struct ConnectSensorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var sensorPushService: SensorPushService
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                } header: {
                    Text("SensorPush Account")
                } footer: {
                    Text("Sign in to your SensorPush account to connect your sensors.")
                }
            }
            .navigationTitle("Connect Sensor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sign In") {
                        Task {
                            await signIn()
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                }
            }
            .disabled(isLoading)
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
    
    private func signIn() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await sensorPushService.signIn(email: email, password: password)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ConnectSensorView()
            .environmentObject(SensorPushService.shared)
    }
} 