import SwiftUI

// MARK: - SensorPush Login View
struct SensorPushLoginView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    let onComplete: (Bool) -> Void
    
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // MARK: - Body
    var body: some View {
        Form {
            Section {
                TextField("Email", text: $username)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textContentType(.password)
            } footer: {
                Text("Enter your SensorPush account credentials")
            }
            
            Section {
                Button {
                    Task {
                        await loginToSensorPush()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Text("Sign In")
                    }
                }
                .disabled(username.isEmpty || password.isEmpty || isLoading)
            }
        }
        .navigationTitle("SensorPush Login")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    onComplete(false)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Methods
    private func loginToSensorPush() async {
        isLoading = true
        // Add SensorPush login logic here
        // For now, just simulate a delay
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        isLoading = false
        onComplete(true)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SensorPushLoginView { success in
            print("Login completed with success: \(success)")
        }
    }
} 