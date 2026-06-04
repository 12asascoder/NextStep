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

            // Colorful face circles
            if showCircles {
                ZStack {
                    // Red circle - top left
                    FaceCircle(
                        color: Color.faceRed,
                        faceType: .round,
                        size: 110
                    )
                    .offset(
                        x: -140,
                        y: circleFloat ? -20 : -30
                    )

                    // Blue circle - top right
                    FaceCircle(
                        color: Color.faceBlue,
                        faceType: .happy,
                        size: 120
                    )
                    .offset(
                        x: 120,
                        y: circleFloat ? -50 : -40
                    )

                    // Yellow circle - center
                    FaceCircle(
                        color: Color.faceYellow,
                        faceType: .smile,
                        size: 100
                    )
                    .offset(
                        x: 0,
                        y: circleFloat ? 20 : 10
                    )

                    // Pink circle - bottom left
                    FaceCircle(
                        color: Color.facePink,
                        faceType: .curly,
                        size: 95
                    )
                    .offset(
                        x: -130,
                        y: circleFloat ? 80 : 90
                    )

                    // Teal/green circle - bottom right
                    FaceCircle(
                        color: Color.faceTeal,
                        faceType: .glasses,
                        size: 115
                    )
                    .offset(
                        x: 155,
                        y: circleFloat ? 100 : 110
                    )
                }
                .frame(height: 260)
                .padding(.top, 20)
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

                    Text("An AI-powered platform that helps you learn by guiding\nyour thinking–not just giving answers.")
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

// MARK: - Face Circle Component

/// A colorful circle with a hand-drawn face doodle on it.
struct FaceCircle: View {
    let color: Color
    let faceType: FaceType
    var size: CGFloat = 100

    enum FaceType {
        case round, happy, smile, curly, glasses
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: size, height: size)

            // Hand-drawn face using Canvas/Path
            faceOverlay
                .frame(width: size * 0.6, height: size * 0.6)
        }
    }

    @ViewBuilder
    private var faceOverlay: some View {
        switch faceType {
        case .round:
            // Simple round eyes and mouth
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    // Eyes
                    Circle()
                        .fill(Color.black)
                        .frame(width: w * 0.12, height: w * 0.12)
                        .offset(x: -w * 0.15, y: -h * 0.1)
                    Circle()
                        .fill(Color.black)
                        .frame(width: w * 0.12, height: w * 0.12)
                        .offset(x: w * 0.15, y: -h * 0.1)
                    // Mouth - little o
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: w * 0.15, height: w * 0.15)
                        .offset(y: h * 0.15)
                    // Hair squiggle on top
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.35, y: -h * 0.15))
                        path.addCurve(
                            to: CGPoint(x: w * 0.5, y: -h * 0.3),
                            control1: CGPoint(x: w * 0.3, y: -h * 0.35),
                            control2: CGPoint(x: w * 0.55, y: -h * 0.35)
                        )
                    }
                    .stroke(Color.black, lineWidth: 2)
                }
            }

        case .happy:
            // Big smile face
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    // Eyes - curved lines
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.25, y: h * 0.3))
                        path.addQuadCurve(
                            to: CGPoint(x: w * 0.4, y: h * 0.3),
                            control: CGPoint(x: w * 0.325, y: h * 0.2)
                        )
                    }
                    .stroke(Color.black, lineWidth: 2.5)

                    Path { path in
                        path.move(to: CGPoint(x: w * 0.6, y: h * 0.3))
                        path.addQuadCurve(
                            to: CGPoint(x: w * 0.75, y: h * 0.3),
                            control: CGPoint(x: w * 0.675, y: h * 0.2)
                        )
                    }
                    .stroke(Color.black, lineWidth: 2.5)

                    // Big smile
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.2, y: h * 0.55))
                        path.addQuadCurve(
                            to: CGPoint(x: w * 0.8, y: h * 0.55),
                            control: CGPoint(x: w * 0.5, y: h * 0.85)
                        )
                    }
                    .stroke(Color.black, lineWidth: 2.5)
                }
            }

        case .smile:
            // Simple smiley
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    // Eyes - dots
                    Circle()
                        .fill(Color.black)
                        .frame(width: w * 0.1, height: w * 0.1)
                        .offset(x: -w * 0.13, y: -h * 0.08)
                    Circle()
                        .fill(Color.black)
                        .frame(width: w * 0.1, height: w * 0.1)
                        .offset(x: w * 0.13, y: -h * 0.08)
                    // Curved smile
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.3, y: h * 0.55))
                        path.addQuadCurve(
                            to: CGPoint(x: w * 0.7, y: h * 0.55),
                            control: CGPoint(x: w * 0.5, y: h * 0.75)
                        )
                    }
                    .stroke(Color.black, lineWidth: 2)
                    // Squiggly hair
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.3, y: h * 0.0))
                        path.addCurve(
                            to: CGPoint(x: w * 0.5, y: -h * 0.1),
                            control1: CGPoint(x: w * 0.35, y: -h * 0.15),
                            control2: CGPoint(x: w * 0.45, y: -h * 0.05)
                        )
                    }
                    .stroke(Color.black, lineWidth: 1.5)
                }
            }

        case .curly:
            // Curly hair face
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    // Curly hair on top
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color.black, lineWidth: 2)
                            .frame(width: w * 0.2, height: w * 0.2)
                            .offset(
                                x: CGFloat(i - 1) * w * 0.18,
                                y: -h * 0.25
                            )
                    }
                    // Eyes
                    Circle()
                        .fill(Color.black)
                        .frame(width: w * 0.09, height: w * 0.09)
                        .offset(x: -w * 0.12, y: -h * 0.02)
                    Circle()
                        .fill(Color.black)
                        .frame(width: w * 0.09, height: w * 0.09)
                        .offset(x: w * 0.12, y: -h * 0.02)
                    // Smile
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.35, y: h * 0.55))
                        path.addQuadCurve(
                            to: CGPoint(x: w * 0.65, y: h * 0.55),
                            control: CGPoint(x: w * 0.5, y: h * 0.7)
                        )
                    }
                    .stroke(Color.black, lineWidth: 2)
                }
            }

        case .glasses:
            // Face with glasses
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    // Glasses frames
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: w * 0.25, height: w * 0.25)
                        .offset(x: -w * 0.12, y: -h * 0.05)
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: w * 0.25, height: w * 0.25)
                        .offset(x: w * 0.12, y: -h * 0.05)
                    // Bridge
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.42, y: h * 0.42))
                        path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.42))
                    }
                    .stroke(Color.black, lineWidth: 2)
                    // Pupils
                    Circle()
                        .fill(Color.black)
                        .frame(width: w * 0.06, height: w * 0.06)
                        .offset(x: -w * 0.12, y: -h * 0.05)
                    Circle()
                        .fill(Color.black)
                        .frame(width: w * 0.06, height: w * 0.06)
                        .offset(x: w * 0.12, y: -h * 0.05)
                    // Mouth - wavy
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.3, y: h * 0.65))
                        path.addCurve(
                            to: CGPoint(x: w * 0.7, y: h * 0.65),
                            control1: CGPoint(x: w * 0.4, y: h * 0.75),
                            control2: CGPoint(x: w * 0.6, y: h * 0.55)
                        )
                    }
                    .stroke(Color.black, lineWidth: 2)
                    // Hair spikes
                    Path { path in
                        path.move(to: CGPoint(x: w * 0.65, y: h * 0.05))
                        path.addLine(to: CGPoint(x: w * 0.72, y: -h * 0.1))
                        path.move(to: CGPoint(x: w * 0.7, y: h * 0.1))
                        path.addLine(to: CGPoint(x: w * 0.8, y: -h * 0.02))
                    }
                    .stroke(Color.black, lineWidth: 2)
                }
            }
        }
    }
}
