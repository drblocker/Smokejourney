import SwiftUI

struct AboutView: View {
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image("AppIcon")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .cornerRadius(20)
                    
                    Text("SmokeJourney")
                        .font(.title2)
                        .bold()
                    
                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            
            Section("Developer") {
                Link(destination: URL(string: "https://github.com/yourusername")!) {
                    Label("GitHub", systemImage: "link")
                }
                
                Link(destination: URL(string: "mailto:your.email@example.com")!) {
                    Label("Contact", systemImage: "envelope")
                }
            }
            
            Section("Legal") {
                NavigationLink(destination: PrivacyPolicyView()) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
                
                NavigationLink(destination: TermsOfServiceView()) {
                    Label("Terms of Service", systemImage: "doc.text")
                }
                
                NavigationLink(destination: LicensesView()) {
                    Label("Licenses", systemImage: "doc.plaintext")
                }
            }
            
            Section("Acknowledgments") {
                Text("SensorPush™ is a trademark of Cousins Group LLC. This app is not affiliated with or endorsed by SensorPush.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("About")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text("Privacy Policy content goes here...")
                .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            Text("Terms of Service content goes here...")
                .padding()
        }
        .navigationTitle("Terms of Service")
    }
}

struct LicensesView: View {
    var body: some View {
        List {
            Section("Open Source Libraries") {
                Text("List of used libraries and their licenses...")
            }
        }
        .navigationTitle("Licenses")
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
} 