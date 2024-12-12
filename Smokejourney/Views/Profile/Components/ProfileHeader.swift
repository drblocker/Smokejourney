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
                Text(user.fullName)
                    .font(.title2)
                    .bold()
                
                if let email = user.email {
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    ProfileHeader(user: User(
        id: "preview",
        email: "test@example.com",
        firstName: "Preview",
        lastName: "User"
    ))
    .previewLayout(.sizeThatFits)
} 