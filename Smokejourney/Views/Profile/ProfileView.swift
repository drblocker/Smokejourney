import SwiftUI
import SwiftData
import PhotosUI
import os.log

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showSignOutAlert = false
    @State private var showImagePicker = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image?
    private let logger = Logger(subsystem: "com.smokejourney", category: "ProfileView")
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let user = authManager.currentUser {
                        HStack {
                            if let profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        
                        PhotosPicker(selection: $selectedImage,
                                   matching: .images,
                                   photoLibrary: .shared()) {
                            Label("Change Profile Photo", systemImage: "photo")
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showSignOutAlert = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await authManager.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .onChange(of: selectedImage) {
                Task {
                    if let data = try? await selectedImage?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        profileImage = Image(uiImage: uiImage)
                        // Save profile image
                        if let user = authManager.currentUser {
                            user.profileImageData = data
                            try? modelContext.save()
                        }
                    }
                }
            }
            .task {
                if let user = authManager.currentUser,
                   let imageData = user.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    profileImage = Image(uiImage: uiImage)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .modelContainer(for: User.self, inMemory: true)
    }
} 
} 