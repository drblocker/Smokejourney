import SwiftUI
import SwiftData

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
                
                Text(user.effectiveEmail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Member since \(user.memberSince)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    ProfileHeader(user: User(id: "preview", email: "test@example.com", name: "Preview User"))
        .previewLayout(.sizeThatFits)
} 