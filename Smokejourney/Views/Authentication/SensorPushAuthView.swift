import SwiftUI

struct SensorPushAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = HumidorEnvironmentViewModel()
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var error: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }
                
                Section {
                    Button(action: authenticate) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Sign In")
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                }
            }
            .navigationTitle("SensorPush Sign In")
            .alert("Authentication Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(error ?? "Unknown error")
            }
        }
    }
    
    private func authenticate() {
        isLoading = true
        Task {
            do {
                try await viewModel.authenticate(email: email, password: password)
                dismiss()
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
} 