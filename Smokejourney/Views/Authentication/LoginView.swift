import SwiftUI
import AuthenticationServices
import SwiftData

struct LoginView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.modelContext) private var modelContext
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                // App logo or branding
                Image(systemName: "smoke")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.accentColor)
                
                Text("Smoke Journey")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 50)
                
                // Sign in button
                SignInWithAppleButton { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    Task {
                        do {
                            try await authManager.handleSignInWithApple(result, context: modelContext)
                        } catch {
                            showingError = true
                            errorMessage = error.localizedDescription
                        }
                    }
                }
                .frame(height: 50)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
            .alert("Sign In Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .task {
                do {
                    try await authManager.restoreUser(from: modelContext)
                } catch {
                    print("Error restoring user: \(error)")
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .modelContainer(for: User.self, inMemory: true)
} 