import SwiftUI

struct SensorPushSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("sensorPushAuthenticated") private var isAuthenticated = false
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var showError = false
    
    var body: some View {
        Form {
            Section {
                if isAuthenticated {
                    HStack {
                        Text("Status")
                        Spacer()
                        Label("Connected", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    
                    Button(role: .destructive, action: signOut) {
                        Text("Sign Out")
                    }
                } else {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                    
                    Button(action: signIn) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Sign In")
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                }
            } header: {
                Text("SensorPush Account")
            } footer: {
                if !isAuthenticated {
                    Text("Sign in with your SensorPush account to enable environmental monitoring.")
                }
            }
        }
        .navigationTitle("SensorPush Settings")
        .alert("Error", isPresented: $showError, presenting: error) { _ in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error)
        }
    }
    
    private func signIn() {
        isLoading = true
        error = nil
        
        Task {
            do {
                try await SensorPushService.shared.signIn(email: email, password: password)
                await MainActor.run {
                    isAuthenticated = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
    
    private func signOut() {
        SensorPushService.shared.signOut()
        isAuthenticated = false
    }
}

#Preview {
    NavigationStack {
        SensorPushSettingsView()
    }
} 