import SwiftUI
import SwiftData
import PhotosUI
import os.log

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var showSignOutAlert = false
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: Image?
    private let logger = Logger(subsystem: "com.smokejourney", category: "ProfileView")
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            Form {
                if let user = authManager.currentUser {
                    Section {
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
                                Text(user.fullName)
                                    .font(.headline)
                                if let email = user.email {
                                    Text(email)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        
                        PhotosPicker(selection: $selectedImage,
                                   matching: .images,
                                   photoLibrary: .shared()) {
                            Label("Change Profile Photo", systemImage: "photo")
                        }
                    }
                    
                    Section("Preferences") {
                        Picker("Temperature Unit", selection: .init(
                            get: { user.preferredTemperatureUnit ?? .fahrenheit },
                            set: { user.preferredTemperatureUnit = $0 }
                        )) {
                            Text("Fahrenheit").tag(TemperatureUnit.fahrenheit)
                            Text("Celsius").tag(TemperatureUnit.celsius)
                        }
                        
                        Picker("Humidity Unit", selection: .init(
                            get: { user.preferredHumidityUnit ?? .percentage },
                            set: { user.preferredHumidityUnit = $0 }
                        )) {
                            Text("Percentage").tag(HumidityUnit.percentage)
                            Text("g/m³").tag(HumidityUnit.gramsPerCubicMeter)
                        }
                        
                        Toggle("Notifications", isOn: .init(
                            get: { user.notificationsEnabled ?? true },
                            set: { user.notificationsEnabled = $0 }
                        ))
                        
                        Toggle("Dark Mode", isOn: .init(
                            get: { user.darkModeEnabled ?? false },
                            set: { user.darkModeEnabled = $0 }
                        ))
                    }
                    
                    Section("Climate") {
                        NavigationLink {
                            EnvironmentalMonitoringTabView()
                        } label: {
                            HStack {
                                Image(systemName: "thermometer")
                                VStack(alignment: .leading) {
                                    Text("Climate Monitoring")
                                    Text("Configure sensors and alerts")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    Section("Settings") {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                        
                        NavigationLink {
                            DataManagementView()
                        } label: {
                            Label("Manage Data", systemImage: "externaldrive")
                        }
                    }
                    
                    Section("Account") {
                        if let memberSince = user.memberSince {
                            LabeledContent("Member Since", value: dateFormatter.string(from: memberSince))
                        }
                        
                        Button(role: .destructive) {
                            showSignOutAlert = true
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
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
