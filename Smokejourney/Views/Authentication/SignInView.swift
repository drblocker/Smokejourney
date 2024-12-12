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
                Task {
                    do {
                        try await authManager.handleSignInWithApple(result, context: modelContext)
                    } catch {
                        self.error = error
                        showError = true
                    }
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