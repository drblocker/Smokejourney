import SwiftUI
import SwiftData

struct SignUpView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var isAuthenticated: Bool
    
    @State private var email = ""
    @State private var displayName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    private var isValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 8 &&
        email.contains("@")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Display Name (Optional)", text: $displayName)
                        .textContentType(.name)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                } footer: {
                    Text("Password must be at least 8 characters")
                }
            }
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sign Up") {
                        signUp()
                    }
                    .disabled(!isValid || isLoading)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
    }
    
    private func signUp() {
        isLoading = true
        
        // Create user
        let user = User(
            email: email,
            displayName: displayName.isEmpty ? nil : displayName
        )
        
        modelContext.insert(user)
        isAuthenticated = true
        dismiss()
    }
}

#Preview {
    SignUpView(isAuthenticated: .constant(false))
        .modelContainer(for: User.self)
} 