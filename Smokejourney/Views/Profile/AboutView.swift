import SwiftUI

struct AboutView: View {
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    
    var body: some View {
        List {
            Section {
                LabeledContent("Version") {
                    Text("\(appVersion) (\(buildNumber))")
                        .foregroundColor(.secondary)
                }
                
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
                
                NavigationLink {
                    TermsOfServiceView()
                } label: {
                    Label("Terms of Service", systemImage: "doc.text")
                }
            } footer: {
                Text("© 2024 SmokeJourney. All rights reserved.")
            }
        }
        .navigationTitle("About")
    }
}

// MARK: - Supporting Views
private struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text("Privacy Policy content will be displayed here.")
                .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

private struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            Text("Terms of Service content will be displayed here.")
                .padding()
        }
        .navigationTitle("Terms of Service")
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
} 