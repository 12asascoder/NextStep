import SwiftUI

/// Wrapper struct to make [MathProblem] a Hashable navigation destination.
struct MathProblemBatch: Hashable {
    let problems: [MathProblem]
}

// MARK: - Main Tab Container

struct ContentView: View {
    @StateObject private var viewModel = CanvasViewModel()
    @State private var navigationPath = NavigationPath()
    @State private var showSolveNew = false
    @State private var selectedTab: AppTab = .home
    @AppStorage("nextstep_userName") private var userName: String = ""

    private let persistence = PersistenceService.shared

    enum AppTab: Int, CaseIterable {
        case home, notebook, profile

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .notebook: return "book.fill"
            case .profile: return "person.fill"
            }
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottom) {
                // Main content based on selected tab
                Group {
                    switch selectedTab {
                    case .home:
                        homeView
                    case .notebook:
                        notebookListView
                    case .profile:
                        ProfileView()
                    }
                }
                .padding(.bottom, 80) // Space for tab bar

                // Custom bottom tab bar
                customTabBar
            }
            .ignoresSafeArea(.keyboard)
            // Single problem destination
            .navigationDestination(for: MathProblem.self) { problem in
                CanvasView(viewModel: viewModel)
                    .onAppear {
                        viewModel.loadProblem(problem)
                    }
            }
            // Multi-problem batch destination
            .navigationDestination(for: MathProblemBatch.self) { batch in
                MultiQuestionSolveView(problems: batch.problems)
            }
            .sheet(isPresented: $showSolveNew) {
                SolveNewSelectionView(
                    onProblemCreated: { newProblem in
                        navigationPath.append(newProblem)
                    },
                    onMultipleProblemsCreated: { problems in
                        navigationPath.append(MathProblemBatch(problems: problems))
                    }
                )
            }
        }
    }

    // MARK: - Home View (Dashboard)

    private var homeView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Top greeting bar
                HStack(alignment: .top) {

                    Text("Hi, \(userName.isEmpty ? "Buddy" : userName)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkColor)

                    Spacer()

                    // Mascot icon (small yellow bee/character)
                    ZStack {
                        Circle()
                            .fill(Color.faceYellow)
                            .frame(width: 36, height: 36)
                        // Simple face
                        VStack(spacing: 2) {
                            HStack(spacing: 4) {
                                Circle().fill(Color.black).frame(width: 3, height: 3)
                                Circle().fill(Color.black).frame(width: 3, height: 3)
                            }
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: 0))
                                path.addQuadCurve(
                                    to: CGPoint(x: 8, y: 0),
                                    control: CGPoint(x: 4, y: 4)
                                )
                            }
                            .stroke(Color.black, lineWidth: 1)
                            .frame(width: 8, height: 4)
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 32)

                // Independence Score Ring
                independenceScoreRing
                    .padding(.bottom, 28)

                // Stats row: Streak + Time
                HStack(spacing: 16) {
                    statPill(systemImage: "flame.fill", value: "\(persistence.currentStreak) Days", color: Color(red: 0.85, green: 0.6, blue: 0.2))
                    statPill(systemImage: "clock.fill", value: persistence.formattedStudyTime, color: Color(red: 0.5, green: 0.6, blue: 0.8))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 20)

                // Action cards
                VStack(spacing: 12) {
                    actionCard(
                        icon: "play.fill",
                        title: "Start Solving",
                        subtitle: "Begin a new productive session",
                        action: { showSolveNew = true }
                    )

                    actionCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Weekly Analysis",
                        subtitle: "View your performance insights",
                        action: { /* TODO: Weekly analysis */ }
                    )
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 32)
            }
        }
        .background(Color.welcomeBg.ignoresSafeArea())
        .onAppear {
            persistence.recordAppUsage()
        }
    }

    // MARK: - Independence Score Ring

    private var independenceScoreRing: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.ringTrack, lineWidth: 14)
                .frame(width: 200, height: 200)

            // Colored arc segments (mimicking the multi-subject ring)
            arcSegment(startAngle: 15, endAngle: 85, color: Color.ringYellow, width: 200)
            arcSegment(startAngle: 105, endAngle: 170, color: Color.ringGreen, width: 200)
            arcSegment(startAngle: 190, endAngle: 260, color: Color.ringBlue, width: 200)
            arcSegment(startAngle: 275, endAngle: 310, color: Color.ringYellow, width: 200)
            arcSegment(startAngle: 325, endAngle: 355, color: Color(red: 0.76, green: 0.9, blue: 0.95), width: 200)

            // Subject icons around the ring
            subjectIcon(systemName: "calculator.fill", angle: 50, radius: 100)
            subjectIcon(systemName: "flask.fill", angle: 137.5, radius: 100)
            subjectIcon(systemName: "pencil", angle: 225, radius: 100)
            subjectIcon(systemName: "pause.fill", angle: 292.5, radius: 100)
            subjectIcon(systemName: "paragraphsign", angle: 340, radius: 100)

            // Center score
            VStack(spacing: 4) {
                Text("\(persistence.aggregateIndependenceScore)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkColor)

                Text("Independence Score")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.inkColor.opacity(0.5))

                Image(systemName: "info.circle")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkColor.opacity(0.3))
            }
        }
        .frame(height: 260)
    }

    // MARK: - Arc Segment

    private func arcSegment(startAngle: Double, endAngle: Double, color: Color, width: CGFloat) -> some View {
        Circle()
            .trim(from: normalizeAngle(startAngle), to: normalizeAngle(endAngle))
            .stroke(color, style: StrokeStyle(lineWidth: 24, lineCap: .round))
            .frame(width: width, height: width)
            .rotationEffect(.degrees(-90))
    }

    private func normalizeAngle(_ degrees: Double) -> CGFloat {
        return CGFloat((degrees + 360).truncatingRemainder(dividingBy: 360) / 360.0)
    }

    // MARK: - Subject Icon

    private func subjectIcon(systemName: String, angle: Double, radius: CGFloat) -> some View {
        let radians = (angle - 90) * .pi / 180
        let x = cos(radians) * Double(radius)
        let y = sin(radians) * Double(radius)

        return Image(systemName: systemName)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Color.inkColor.opacity(0.5))
            .offset(x: x, y: y)
    }

    // MARK: - Stat Pill

    private func statPill(systemImage: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.paperWhite)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.paperBorder, lineWidth: 1)
        )
    }

    // MARK: - Action Card

    private func actionCard(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Color.inkColor.opacity(0.7))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkColor)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.inkColor.opacity(0.6))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.paperWhite)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.paperBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Notebook List (Sums)

    private var notebookListView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom) {
                Text("Sums")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkColor)
                Spacer()
                Button(action: { showSolveNew = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("Solve New")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.solveBtnBg)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 24)

            List(MathProblem.samples) { problem in
                NavigationLink(value: problem) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(problem.title)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.inkColor)
                        Text(problem.statement)
                            .font(.custom("Bradley Hand", size: 15))
                            .lineLimit(2)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.paperWhite)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.paperBorder, lineWidth: 0.5)
                    )
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .padding(.vertical, 6)
            }
            .listStyle(.plain)
        }
        .background(Color.welcomeBg.ignoresSafeArea())
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedTab = tab
                    }
                }) {
                    if tab == .notebook {
                        // Center raised button
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 56, height: 56)
                                .shadow(color: Color.black.opacity(0.1), radius: 8, y: -2)

                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(Color.tabBarDark)
                        }
                        .offset(y: -14)
                    } else {
                        VStack(spacing: 0) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(
                                    selectedTab == tab
                                    ? Color.white
                                    : Color.white.opacity(0.4)
                                )
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.tabBarDark)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Placeholder Tab

    private func placeholderTab(icon: String, title: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color.inkColor.opacity(0.2))
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.inkColor.opacity(0.3))
            Text("Coming soon")
                .font(.system(size: 14))
                .foregroundStyle(Color.inkColor.opacity(0.2))
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.welcomeBg.ignoresSafeArea())
    }

}

// MARK: - Profile View

struct ProfileView: View {
    @AppStorage("nextstep_userName") private var userName: String = ""
    @State private var isEditingName = false
    @State private var editedName: String = ""

    private let persistence = PersistenceService.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Profile header
                profileHeader
                    .padding(.top, 32)
                    .padding(.bottom, 28)

                // Stats section
                statsSection
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)

                // Settings section
                settingsSection
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)

                // About section
                aboutSection
                    .padding(.horizontal, 28)
                    .padding(.bottom, 32)
            }
        }
        .background(Color.welcomeBg.ignoresSafeArea())
        .alert("Edit Name", isPresented: $isEditingName) {
            TextField("Your name", text: $editedName)
            Button("Save") {
                userName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter your display name")
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.ringYellow, Color.ringGreen, Color.ringBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                // Inner white circle with initial
                Circle()
                    .fill(Color.paperWhite)
                    .frame(width: 90, height: 90)

                Text(userInitial)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkColor)
            }

            // Name
            Text(userName.isEmpty ? "Buddy" : userName)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkColor)

            // Edit name button
            Button(action: {
                editedName = userName
                isEditingName = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Edit Name")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Color.accentBlue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.accentBlue.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Progress")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkColor)
                .padding(.bottom, 4)

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                statCard(
                    icon: "flame.fill",
                    iconColor: Color.streakOrange,
                    title: "\(persistence.currentStreak)",
                    subtitle: "Day Streak"
                )

                statCard(
                    icon: "clock.fill",
                    iconColor: Color.timeGreen,
                    title: persistence.formattedStudyTime,
                    subtitle: "Study Time"
                )

                statCard(
                    icon: "star.fill",
                    iconColor: Color.ringYellow,
                    title: "\(persistence.aggregateIndependenceScore)",
                    subtitle: "Independence"
                )

                statCard(
                    icon: "lightbulb.fill",
                    iconColor: Color.accentAmber,
                    title: "\(persistence.totalHintsUsed)",
                    subtitle: "Hints Used"
                )
            }

            // Sessions count
            let sessionCount = persistence.loadAllSessions().count
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.accentBlue)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(sessionCount) Problem\(sessionCount == 1 ? "" : "s") Solved")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkColor)
                    Text("Total problems attempted")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.inkColor.opacity(0.5))
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.paperWhite)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.paperBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkColor)
                .padding(.bottom, 4)

            settingsRow(icon: "bell.fill", title: "Notifications", subtitle: "Reminders to study")
            settingsRow(icon: "moon.fill", title: "Appearance", subtitle: "Light & dark mode")
            settingsRow(icon: "lock.fill", title: "Privacy", subtitle: "Data & permissions")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkColor)
                .padding(.bottom, 4)

            // App version
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.ringYellow.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.ringYellow)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("NextStep")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkColor)
                    Text("Version 1.0 · Made with ❤️")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.inkColor.opacity(0.5))
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.paperWhite)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.paperBorder, lineWidth: 1)
            )

            // Reset data button
            Button(action: {
                persistence.clearAll()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14))
                    Text("Reset All Data")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Color.solveBtnBg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.solveBtnBg.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.solveBtnBg.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func statCard(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(iconColor)

            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkColor)

            Text(subtitle)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkColor.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.paperWhite)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.paperBorder, lineWidth: 1)
        )
    }

    private func settingsRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentBlue.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.accentBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkColor)
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.inkColor.opacity(0.5))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.inkColor.opacity(0.3))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.paperWhite)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.paperBorder, lineWidth: 1)
        )
    }

    private var userInitial: String {
        let name = userName.isEmpty ? "B" : userName
        return String(name.prefix(1)).uppercased()
    }
}
