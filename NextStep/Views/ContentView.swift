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
                    statPill(emoji: "🔥", value: "\(persistence.currentStreak) Days", color: Color.streakOrange)
                    statPill(emoji: "🕐", value: persistence.formattedStudyTime, color: Color.timeGreen)
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
            // Yellow segment (top-right)
            arcSegment(
                startAngle: -60,
                endAngle: 10,
                color: Color.ringYellow,
                width: 200
            )

            // Blue/lavender segment (left)
            arcSegment(
                startAngle: 140,
                endAngle: 220,
                color: Color.ringBlue,
                width: 200
            )

            // Green segment (bottom-right)
            arcSegment(
                startAngle: 230,
                endAngle: 310,
                color: Color.ringGreen,
                width: 200
            )

            // Olive/dark segment (bottom-left, partial)
            arcSegment(
                startAngle: 315,
                endAngle: 340,
                color: Color.ringOlive,
                width: 200
            )

            // Subject icons around the ring
            subjectIcon(systemName: "pencil.tip", angle: 155, radius: 115, bgColor: Color.ringYellow)
            subjectIcon(systemName: "paragraphsign", angle: -75, radius: 115, bgColor: Color.ringBlue.opacity(0.7))
            subjectIcon(systemName: "tablecells", angle: -40, radius: 115, bgColor: Color.ringYellow)
            subjectIcon(systemName: "flask.fill", angle: 285, radius: 115, bgColor: Color.ringOlive)
            subjectIcon(systemName: "pause.fill", angle: 185, radius: 115, bgColor: Color.ringYellow.opacity(0.7))

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
            .stroke(color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
            .frame(width: width, height: width)
            .rotationEffect(.degrees(-90))
    }

    private func normalizeAngle(_ degrees: Double) -> CGFloat {
        return CGFloat((degrees + 360).truncatingRemainder(dividingBy: 360) / 360.0)
    }

    // MARK: - Subject Icon

    private func subjectIcon(systemName: String, angle: Double, radius: CGFloat, bgColor: Color) -> some View {
        let radians = (angle - 90) * .pi / 180
        let x = cos(radians) * Double(radius)
        let y = sin(radians) * Double(radius)

        return Image(systemName: systemName)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(Color.inkColor.opacity(0.6))
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(bgColor.opacity(0.5))
            )
            .offset(x: x, y: y)
    }

    // MARK: - Stat Pill

    private func statPill(emoji: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 20))
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
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.inkColor.opacity(0.6))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.inkColor)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.inkColor.opacity(0.45))
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
