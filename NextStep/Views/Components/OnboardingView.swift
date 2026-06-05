import SwiftUI

/// Welcome screen matching the reference design:
/// - Cream background
/// - "nextstep" bold lowercase title
/// - 5 colorful circles with hand-drawn face doodles
/// - Tagline: "Learn smarter. One step at a time."
/// - "Get Started" dark pill button
///
/// Phase 1: Name input (greeting)
/// Phase 2: Welcome screen (the reference design)
struct OnboardingView: View {
    var onComplete: (String) -> Void

    // MARK: - State

    @State private var phase: OnboardingPhase = .greeting
    @State private var userName: String = ""
    @FocusState private var isNameFieldFocused: Bool

    // Animation flags - greeting
    @State private var showGreeting = false
    @State private var showSubtitle = false
    @State private var showNameField = false
    @State private var showContinueButton = false

    // Animation flags - welcome
    @State private var showLogo = false
    @State private var showCircles = false
    @State private var showTagline = false
    @State private var showGetStarted = false
    @State private var circleFloat = false

    enum OnboardingPhase {
        case greeting
        case welcome
    }

    var body: some View {
        ZStack {
            // Warm cream background
            Color.welcomeBg
                .ignoresSafeArea()

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

    // MARK: - Phase 1: Greeting (Name Input)

    private var greetingPhase: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Wave emoji
                if showGreeting {
                    Text("👋")
                        .font(.system(size: 64))
                        .transition(.scale.combined(with: .opacity))
                }

                // "Hello!"
                if showGreeting {
                    Text("Hello!")
                        .font(.system(size: 48, weight: .bold, design: .serif))
                        .foregroundStyle(Color.inkColor)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Subtitle
                if showSubtitle {
                    Text("Can I know your name?")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.inkColor.opacity(0.6))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Name input field
                if showNameField {
                    VStack(spacing: 20) {
                        HStack(spacing: 0) {
                            TextField("", text: $userName, prompt:
                                Text("Type your name…")
                                    .foregroundColor(Color.inkColor.opacity(0.3))
                            )
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.inkColor)
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
                                .fill(Color.inkColor.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.inkColor.opacity(0.12), lineWidth: 1)
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
                                .fill(Color.welcomeButtonBg)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
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

    // MARK: - Phase 2: Welcome (Reference Design)

    private var welcomePhase: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 80)

            // "nextstep" logo title
            if showLogo {
                Text("nextstep")
                    .font(.system(size: 64, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.inkColor)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }

            // Illustration
            if showCircles {
                Group {
                    if let uiImage = UIImage(contentsOfFile: "/Users/ayushsharma/.gemini/antigravity-ide/brain/6bb68c58-4e53-4f4c-9287-c28ef6b49319/welcome_illustration_1780641088314.png") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 380)
                            .blendMode(.multiply)
                            .padding(.top, 20)
                    } else {
                        Image(systemName: "book.pages")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .foregroundColor(.blue)
                    }
                }
                .transition(.scale(scale: 0.5).combined(with: .opacity))
            }

            Spacer()

            // Tagline
            if showTagline {
                VStack(spacing: 16) {
                    Text("Learn smarter.\nOne step at a time.")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.inkColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text("An AI-powered platform that helps you learn by guiding\nyour thinking.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color.inkColor.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // "Get Started" button
            if showGetStarted {
                Button(action: {
                    let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
                    onComplete(trimmed)
                }) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(Color.welcomeButtonBg)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.top, 28)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }

            Spacer()
                .frame(height: 80)
        }
        .padding(.horizontal, 40)
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
        withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.3)) {
            showLogo = true
        }
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.7)) {
            showCircles = true
        }
        // Start floating animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                circleFloat = true
            }
        }
        withAnimation(.easeOut(duration: 0.6).delay(1.3)) {
            showTagline = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.8)) {
            showGetStarted = true
        }
    }
}


