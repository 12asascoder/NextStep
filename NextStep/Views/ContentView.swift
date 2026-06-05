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
    @State private var showAnalysis: Bool = false
    @State private var showProfile: Bool = false
    @State private var userProblems: [MathProblem] = []

    private let persistence = PersistenceService.shared

    enum AppTab: Int, CaseIterable {
        case home, camera, history

        var icon: String {
            switch self {
            case .home: return "house"
            case .camera: return "camera"
            case .history: return "chart.pie"
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
                    case .camera:
                        Color.clear
                    case .history:
                        notebookListView
                    }
                }
                .padding(.bottom, 80) // Space for tab bar

                // Custom bottom tab bar
                customTabBar
            }
            .ignoresSafeArea(.keyboard)
            .fullScreenCover(isPresented: $showAnalysis) {
                AnalysisView()
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
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
                    Button(action: { showProfile = true }) {
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
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 32)

                // Independence Score Ring
                streaksRing
                    .padding(.bottom, 28)

                // Stats row: Streak + Time
                statPill(systemImage: "clock.fill", value: persistence.formattedStudyTime, color: Color(red: 0.5, green: 0.6, blue: 0.8))
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
                        action: { showAnalysis = true }
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

    private var streaksRing: some View {
        ZStack {
            // Colored arc segments (pill style with gaps)
            arcSegment(startAngle: 15, endAngle: 80, color: Color.ringYellow, width: 260)
            arcSegment(startAngle: 105, endAngle: 165, color: Color.ringGreen, width: 260)
            arcSegment(startAngle: 195, endAngle: 255, color: Color.ringBlue, width: 260)
            arcSegment(startAngle: 280, endAngle: 310, color: Color(red: 0.95, green: 0.5, blue: 0.5), width: 260)
            arcSegment(startAngle: 335, endAngle: 355, color: Color(red: 0.76, green: 0.9, blue: 0.95), width: 260)

            // Subject icons around the ring
            subjectIcon(systemName: "calculator.fill", angle: 47.5, radius: 130)
            subjectIcon(systemName: "flask.fill", angle: 135, radius: 130)
            subjectIcon(systemName: "pencil", angle: 225, radius: 130)
            subjectIcon(systemName: "pause.fill", angle: 295, radius: 130)
            subjectIcon(systemName: "paragraphsign", angle: 345, radius: 130)

            // Center score
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text("\(persistence.currentStreak)")
                        .font(.system(size: 76, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.streakOrange)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.streakOrange)
                        .offset(y: 4)
                }

                Text("Streaks")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.streakOrange)
            }
        }
        .frame(height: 320)
    }

    // MARK: - Arc Segment

    private func arcSegment(startAngle: Double, endAngle: Double, color: Color, width: CGFloat) -> some View {
        Circle()
            .trim(from: normalizeAngle(startAngle), to: normalizeAngle(endAngle))
            .stroke(color, style: StrokeStyle(lineWidth: 28, lineCap: .round))
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
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Color.inkColor.opacity(0.5))
            .offset(x: x, y: y)
    }

    // MARK: - Stat Pill

    private func statPill(systemImage: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
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
            HStack(spacing: 18) {
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.inkColor.opacity(0.7))
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkColor)
                    Text(subtitle)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.inkColor.opacity(0.6))
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
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

            if userProblems.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(Color.inkColor.opacity(0.2))
                    Text("No problems solved yet")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(Color.inkColor.opacity(0.5))
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 60)
            } else {
                List(userProblems) { problem in
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
        }
        .background(Color.welcomeBg.ignoresSafeArea())
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 16) {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                Button(action: {
                    if tab == .camera {
                        showSolveNew = true
                    } else {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedTab = tab
                        }
                    }
                }) {
                    ZStack {
                        Capsule()
                            .fill(Color(red: 0.92, green: 0.9, blue: 0.86))
                            .frame(height: 44)

                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.inkColor)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color(red: 0.35, green: 0.35, blue: 0.35))
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
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
// MARK: - Analysis View

struct AnalysisView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Top header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left.circle")
                                .font(.system(size: 20))
                            Text("Analysis")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.92, green: 0.9, blue: 0.86))
                        )
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // 1. No. of problems solved in one week
                VStack(alignment: .leading, spacing: 20) {
                    Text("No. of problems solved in one week")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.black.opacity(0.7))
                    
                    HStack(alignment: .bottom, spacing: 0) {
                        barColumn(height: 0, label: "Mon")
                        barColumn(height: 0, label: "Tue")
                        barColumn(height: 0, label: "Wed")
                        barColumn(height: 0, label: "Thur")
                        barColumn(height: 0, label: "Fri")
                        barColumn(height: 0, label: "Sat")
                        barColumn(height: 0, label: "Sun")
                    }
                    .frame(height: 140)
                    
                    // Simple x-axis line
                    Rectangle()
                        .fill(Color.black.opacity(0.2))
                        .frame(height: 1)
                        .padding(.horizontal, 12)
                }
                .padding(24)
                .background(Color(red: 0.98, green: 0.97, blue: 0.95))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.1), lineWidth: 1))
                .padding(.horizontal, 24)

                // 2 & 3. Pie Charts (Accuracy & Subject)
                HStack(spacing: 20) {
                    // Accuracy
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Accuracy Distribution")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.black.opacity(0.7))
                        
                        HStack(spacing: 16) {
                            pieChart(colors: [Color.gray.opacity(0.2)], portions: [1.0])
                                .frame(width: 100, height: 100)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                legendItem(color: Color.ringGreen, label: "Correct", value: "0%")
                                legendItem(color: Color(red: 0.95, green: 0.4, blue: 0.4), label: "Incorrect", value: "0%")
                                legendItem(color: Color.ringYellow, label: "Skipped", value: "0%")
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.98, green: 0.97, blue: 0.95))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.1), lineWidth: 1))

                    // Subject
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Subject Distribution")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.black.opacity(0.7))
                        
                        HStack(spacing: 16) {
                            pieChart(colors: [Color.gray.opacity(0.2)], portions: [1.0])
                                .frame(width: 100, height: 100)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                legendItem(color: Color.ringGreen, label: "Maths", value: "0%")
                                legendItem(color: Color(red: 0.95, green: 0.4, blue: 0.6), label: "Bio", value: "0%")
                                legendItem(color: Color.ringYellow, label: "Chemistry", value: "0%")
                                legendItem(color: Color.ringBlue, label: "Calculus", value: "0%")
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.98, green: 0.97, blue: 0.95))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.1), lineWidth: 1))
                }
                .padding(.horizontal, 24)

                // 4 & 5. Topics and Hints
                HStack(alignment: .top, spacing: 20) {
                    // Recommended Next Topics
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Recommended Next Topics")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.black.opacity(0.7))
                            Text("No data available yet. Keep solving problems to get personalized recommendations.")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.black.opacity(0.5))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        topicCard(icon: "pencil", color: Color(red: 0.95, green: 0.4, blue: 0.4), title: "Practice Logarithms", questions: "5 Questions")
                        topicCard(icon: "flask.fill", color: Color.ringGreen, title: "Halo-alkanes Numericals", questions: "5 Questions")
                        topicCard(icon: "book.closed.fill", color: Color.ringBlue, title: "Review Trigonometry Identities", questions: "5 Questions")
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.98, green: 0.97, blue: 0.95))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.1), lineWidth: 1))

                    // Hints Used vs. Problem Solved
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Hints Used vs. Problem Solved")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.black.opacity(0.7))
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                legendItem(color: Color(red: 0.7, green: 0.9, blue: 0.7), label: "Independent Solving")
                                legendItem(color: Color(red: 0.95, green: 0.6, blue: 0.6), label: "Guided")
                            }
                        }
                        
                        // Stacked Bar Chart
                        HStack(alignment: .bottom, spacing: 0) {
                            stackedBarColumn(indep: 40, guided: 30, label: "Mon")
                            stackedBarColumn(indep: 45, guided: 20, label: "Tue")
                            stackedBarColumn(indep: 25, guided: 25, label: "Wed")
                            stackedBarColumn(indep: 35, guided: 25, label: "Thur")
                            stackedBarColumn(indep: 20, guided: 35, label: "Fri")
                            stackedBarColumn(indep: 25, guided: 10, label: "Sat")
                            stackedBarColumn(indep: 50, guided: 30, label: "Sun")
                        }
                        .frame(height: 160)
                        .padding(.top, 8)
                        
                        // Simple x-axis line
                        Rectangle()
                            .fill(Color.black.opacity(0.2))
                            .frame(height: 1)
                            .padding(.horizontal, 12)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.98, green: 0.97, blue: 0.95))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.1), lineWidth: 1))
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 60)
            }
        }
        .background(Color(red: 0.96, green: 0.94, blue: 0.88).ignoresSafeArea())
    }

    private func barColumn(height: CGFloat, label: String) -> some View {
        VStack(spacing: 8) {
            Spacer()
            Rectangle()
                .fill(Color(red: 0.7, green: 0.9, blue: 0.7))
                .frame(width: 44, height: height)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    private func stackedBarColumn(indep: CGFloat, guided: CGFloat, label: String) -> some View {
        VStack(spacing: 8) {
            Spacer()
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color(red: 0.95, green: 0.6, blue: 0.6))
                    .frame(width: 32, height: guided)
                    .cornerRadius(16, corners: [.topLeft, .topRight])
                Rectangle()
                    .fill(Color(red: 0.7, green: 0.9, blue: 0.7))
                    .frame(width: 32, height: indep)
            }
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    private func pieChart(colors: [Color], portions: [Double]) -> some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            var startAngle = Angle.zero
            
            for (index, portion) in portions.enumerated() {
                let endAngle = startAngle + Angle(degrees: portion * 360)
                let path = Path { p in
                    p.move(to: center)
                    p.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                }
                context.fill(path, with: .color(colors[index]))
                startAngle = endAngle
            }
        }
    }

    private func legendItem(color: Color, label: String, value: String? = nil) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black.opacity(0.6))
            if let v = value {
                Spacer()
                Text(v)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black.opacity(0.8))
            }
        }
    }

    private func topicCard(icon: String, color: Color, title: String, questions: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.black.opacity(0.8))
                Text(questions)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.black.opacity(0.5))
            }
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.05), lineWidth: 1))
    }
}

// Extension for corner radius on specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
