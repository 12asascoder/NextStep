import SwiftUI

@main
struct NextStepApp: App {
    @AppStorage("nextstep_userName") private var userName: String = ""
    @State private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if userName.isEmpty && !hasCompletedOnboarding {
                OnboardingView { name in
                    withAnimation(.easeInOut(duration: 0.6)) {
                        userName = name
                        hasCompletedOnboarding = true
                    }
                }
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
    }
}
