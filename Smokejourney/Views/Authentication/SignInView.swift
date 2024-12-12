import SwiftUI
import AuthenticationServices
import SwiftData

struct SignInView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.modelContext) private var modelContext
    @State private var showError = false
    @State private var error: Error?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "smoke")
                .font(.system(size: 60))
                .foregroundStyle(.tint)
            
            Text("Welcome to Smokejourney")
                .font(.title)
                .bold()
            
            Text("Track and manage your cigar collection")
                .foregroundStyle(.secondary)
            
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let authorization):
                    guard let credentials = authorization.credential as? ASAuthorizationAppleIDCredential else {
                        showError = true
                        error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])
                        return
                    }
                    Task {
                        do {
                            try await authManager.handleSignInWithApple(credentials, context: modelContext)
                        } catch {
                            self.error = error
                            showError = true
                        }
                    }
                case .failure(let error):
                    self.error = error
                    showError = true
                }
            }
            .frame(height: 45)
            .padding(.horizontal, 40)
        }
        .padding()
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(error?.localizedDescription ?? "An unknown error occurred")
        }
    }
}

#Preview {
    SignInView()
        .modelContainer(for: User.self, inMemory: true)
        .environmentObject(AuthenticationManager.shared)
} 