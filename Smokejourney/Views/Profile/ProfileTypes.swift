import SwiftUI
import SwiftData

// MARK: - Profile View Components
struct ProfileHeader: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.accentColor)
            
            VStack(spacing: 4) {
                Text(user.effectiveName)
                    .font(.title2)
                    .bold()
                
                if let email = user.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(user.memberSince)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
} 