import SwiftUI

/// Animated onboarding flow:
/// Phase 1 — "Hello, can I know your name?"  (typewriter text + name input)
/// Phase 2 — "Hello [name], welcome to The Next Step"  (cinematic reveal)
/// Shown only on first launch; name is persisted in UserDefaults.
struct OnboardingView: View {
    var onComplete: (String) -> Void

    // MARK: - State

    @State private var phase: OnboardingPhase = .greeting
    @State private var userName: String = ""
    @FocusState private var isNameFieldFocused: Bool

    // Animation flags
    @State private var showGreeting = false
    @State private var showSubtitle = false
    @State private var showNameField = false
    @State private var showContinueButton = false

    // Welcome phase
    @State private var showWelcomeHello = false
    @State private var showWelcomeName = false
    @State private var showWelcomeTagline = false
    @State private var showWelcomeLogo = false
    @State private var showGetStarted = false
    @State private var backgroundGlow = false
    @State private var particlesVisible = false

    enum OnboardingPhase {
        case greeting
        case welcome
    }

    var body: some View {
        ZStack {
            // Animated background
            animatedBackground

            switch phase {
            case .greeting:
                greetingPhase
                    .transition(.opacity)

            case .welcome:
                welcomePhase
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startGreetingAnimations()
        }
    }

    // MARK: - Animated Background

    private var animatedBackground: some View {
        ZStack {
            // Deep gradient base
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.07, blue: 0.14),
                    Color(red: 0.05, green: 0.10, blue: 0.22),
                    Color(red: 0.08, green: 0.06, blue: 0.18),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Floating orbs
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.accentBlue.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: backgroundGlow ? -60 : -120, y: backgroundGlow ? -100 : -60)
                .animation(
                    .easeInOut(duration: 6).repeatForever(autoreverses: true),
                    value: backgroundGlow
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.accentGreen.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 350, height: 350)
                .offset(x: backgroundGlow ? 150 : 100, y: backgroundGlow ? 200 : 250)
                .animation(
                    .easeInOut(duration: 8).repeatForever(autoreverses: true),
                    value: backgroundGlow
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple.opacity(0.12), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: backgroundGlow ? 80 : 40, y: backgroundGlow ? -180 : -220)
                .animation(
                    .easeInOut(duration: 7).repeatForever(autoreverses: true),
                    value: backgroundGlow
                )

            // Subtle dot grid overlay
            DotGridBackground(spacing: 30, dotSize: 1, color: .white.opacity(0.04))
        }
        .onAppear {
            backgroundGlow = true
        }
    }

    // MARK: - Phase 1: Greeting

    private var greetingPhase: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Animated hand wave emoji
                if showGreeting {
                    Text("👋")
                        .font(.system(size: 64))
                        .transition(.scale.combined(with: .opacity))
                }

                // "Hello!" typewriter
                if showGreeting {
                    Text("Hello!")
                        .font(.system(size: 48, weight: .bold, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Subtitle
                if showSubtitle {
                    Text("Can I know your name?")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Name input field
                if showNameField {
                    VStack(spacing: 20) {
                        HStack(spacing: 0) {
                            TextField("", text: $userName, prompt:
                                Text("Type your name…")
                                    .foregroundColor(.white.opacity(0.3))
                            )
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .focused($isNameFieldFocused)
                            .submitLabel(.continue)
                            .onSubmit { advanceToWelcome() }
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(.white.opacity(0.15), lineWidth: 1)
                                )
                        )
                        .frame(maxWidth: 400)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Continue button
                if showContinueButton {
                    Button(action: advanceToWelcome) {
                        HStack(spacing: 10) {
                            Text("Continue")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.accentBlue, Color.accentBlue.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: Color.accentBlue.opacity(0.4), radius: 12, y: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Phase 2: Welcome

    private var welcomePhase: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                // Logo icon
                if showWelcomeLogo {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentBlue.opacity(0.3), Color.accentGreen.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .blur(radius: 20)

                        Image(systemName: "function")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.accentBlue, Color.accentGreen],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
                }

                // "Hello, [Name]!"
                if showWelcomeHello {
                    Text("Hello, \(userName.trimmingCharacters(in: .whitespacesAndNewlines))!")
                        .font(.system(size: 42, weight: .bold, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color.accentBlue.opacity(0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .multilineTextAlignment(.center)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // "Welcome to"
                if showWelcomeName {
                    VStack(spacing: 8) {
                        Text("Welcome to")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))

                        Text("The Next Step")
                            .font(.system(size: 36, weight: .heavy, design: .serif))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.accentGreen, Color.accentBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Tagline
                if showWelcomeTagline {
                    Text("Your AI-powered math companion")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .transition(.opacity)
                }

                // Get Started button
                if showGetStarted {
                    Button(action: {
                        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
                        onComplete(trimmed)
                    }) {
                        HStack(spacing: 10) {
                            Text("Get Started")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.accentBlue, Color.accentGreen],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: Color.accentBlue.opacity(0.35), radius: 16, y: 6)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 16)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Animation Sequences

    private func startGreetingAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
            showGreeting = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.9)) {
            showSubtitle = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(1.4)) {
            showNameField = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            isNameFieldFocused = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(1.8)) {
            showContinueButton = true
        }
    }

    private func advanceToWelcome() {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isNameFieldFocused = false

        withAnimation(.easeInOut(duration: 0.5)) {
            phase = .welcome
        }

        // Staggered welcome animations
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.3)) {
            showWelcomeLogo = true
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.7)) {
            showWelcomeHello = true
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(1.2)) {
            showWelcomeName = true
        }
        withAnimation(.easeOut(duration: 0.6).delay(1.8)) {
            showWelcomeTagline = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(2.3)) {
            showGetStarted = true
        }
    }
}
