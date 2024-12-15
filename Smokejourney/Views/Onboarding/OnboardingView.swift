import SwiftUI

struct OnboardingView: View {
    @AppStorage("isOnboarding") private var isOnboarding = true
    
    var body: some View {
        TabView {
            OnboardingPage(
                title: "Welcome to SmokeJourney",
                description: "Track and monitor your cigar collection with ease",
                imageName: "humidor.fill"
            )
            
            OnboardingPage(
                title: "Climate Monitoring",
                description: "Keep your cigars in perfect condition with real-time temperature and humidity tracking",
                imageName: "thermometer"
            )
            
            OnboardingPage(
                title: "Smart Integration",
                description: "Connect with HomeKit and SensorPush devices for automated monitoring",
                imageName: "sensor.fill",
                isLastPage: true,
                onComplete: { isOnboarding = false }
            )
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

private struct OnboardingPage: View {
    let title: String
    let description: String
    let imageName: String
    var isLastPage = false
    var onComplete: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: imageName)
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            Text(title)
                .font(.title)
                .bold()
            
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            if isLastPage {
                Button("Get Started") {
                    onComplete?()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
        }
    }
}

#Preview {
    OnboardingView()
} 