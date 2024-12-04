import SwiftUI
import SwiftData
import AuthenticationServices

struct LoginView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isAuthenticated: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showSignUp = false
    
    private var isValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                SecureField("Password", text: $password)
                    .textContentType(.password)
            }
            
            Section {
                Button(action: signIn) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Sign In")
                    }
                }
                .disabled(!isValid || isLoading)
                
                Button("Create Account") {
                    showSignUp = true
                }
            }
        }
        .navigationTitle("Sign In")
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showSignUp) {
            NavigationStack {
                SignUpView(isAuthenticated: $isAuthenticated)
            }
        }
    }
    
    private func signIn() {
        isLoading = true
        
        Task {
            do {
                let user = try await AuthenticationManager.shared.signIn(email: email, password: password)
                modelContext.insert(user)
                isAuthenticated = true
            } catch let error as AuthError {
                errorMessage = error.localizedDescription
                showError = true
            } catch {
                errorMessage = "An unexpected error occurred"
                showError = true
            }
            isLoading = false
        }
    }
} 