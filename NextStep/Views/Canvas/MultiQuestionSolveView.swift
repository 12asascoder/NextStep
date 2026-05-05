import SwiftUI
import PencilKit

/// Board-style grid of question cards for multi-question solving.
/// Each card shows a thumbnail preview of the canvas (or blank if unstarted).
/// Tapping opens the full canvas. Hover / long-press reveals the full question text.
struct MultiQuestionSolveView: View {
    let problems: [MathProblem]

    @State private var viewModels: [CanvasViewModel] = []
    @State private var isInitialized = false
    @State private var selectedIndex: Int? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]

    var body: some View {
        Group {
            if isInitialized {
                if let idx = selectedIndex, viewModels.indices.contains(idx) {
                    // Full-screen canvas for the selected question
                    questionCanvasView(index: idx, vm: viewModels[idx])
                } else {
                    // Board grid
                    boardGridView
                }
            } else {
                VStack {
                    Spacer()
                    ProgressView("Setting up questions…")
                        .font(NSFont.body)
                    Spacer()
                }
                .background(Color.paperCard.ignoresSafeArea())
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !isInitialized else { return }
            viewModels = problems.map { CanvasViewModel(problem: $0) }
            isInitialized = true
        }
    }

    // MARK: - Board Grid

    private var boardGridView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Questions")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundStyle(Color.textPrimary)
                    Text("\(problems.count) questions · tap to solve")
                        .font(NSFont.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()

                // Progress summary
                let solved = viewModels.filter { $0.problemComplete }.count
                if solved > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.accentGreen)
                        Text("\(solved)/\(problems.count)")
                            .font(NSFont.heading)
                            .foregroundStyle(Color.accentGreen)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.accentGreen.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 20)

            Divider().background(Color.blockBorder)

            // Card Grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(Array(viewModels.enumerated()), id: \.offset) { index, vm in
                        QuestionBoardCard(
                            index: index,
                            viewModel: vm,
                            onTap: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    selectedIndex = index
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 20)
            }
        }
        .background(Color.paperCard.ignoresSafeArea())
    }

    // MARK: - Full Canvas View (for selected question)

    @ViewBuilder
    private func questionCanvasView(index: Int, vm: CanvasViewModel) -> some View {
        VStack(spacing: 0) {
            // Navigation bar for returning to grid
            HStack {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        selectedIndex = nil
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("All Questions")
                            .font(NSFont.body)
                    }
                    .foregroundStyle(Color.accentBlue)
                }
                .buttonStyle(.plain)

                Spacer()

                // Question number + navigation dots
                HStack(spacing: 8) {
                    ForEach(0..<viewModels.count, id: \.self) { i in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedIndex = i
                            }
                        } label: {
                            Text("Q\(i + 1)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(i == index ? .white : questionColor(for: i))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    i == index
                                        ? questionColor(for: i)
                                        : questionColor(for: i).opacity(0.15)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.paperBackground)

            Divider().background(Color.blockBorder)

            CanvasView(viewModel: vm)
        }
    }

    private func questionColor(for index: Int) -> Color {
        let colors: [Color] = [.accentBlue, .accentGreen, .accentAmber, Color.purple]
        return colors[index % colors.count]
    }
}

// MARK: - Question Board Card

/// A Freeform-style card showing a thumbnail of the canvas,
/// question title/number, and status. Hover shows the full question text.
struct QuestionBoardCard: View {
    let index: Int
    @ObservedObject var viewModel: CanvasViewModel
    var onTap: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false
    @State private var thumbnailImage: UIImage? = nil

    private var tabColor: Color {
        let colors: [Color] = [.accentBlue, .accentGreen, .accentAmber, Color.purple]
        return colors[index % colors.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Canvas Thumbnail Area
            ZStack {
                // Background
                Color.white

                // Drawing preview (if user has worked on this)
                if let thumb = thumbnailImage {
                    Image(uiImage: thumb)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                } else {
                    // Empty canvas placeholder with dot grid
                    DotGridBackground(spacing: 14, dotSize: 1.5, color: Color.textSecondary.opacity(0.15))
                }

                // Completion overlay
                if viewModel.problemComplete {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.accentGreen)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .padding(8)
                        }
                    }
                }

                // Hover overlay — shows full question text
                if isHovered {
                    ZStack {
                        Color.black.opacity(0.65)

                        ScrollView {
                            Text(viewModel.problem.statement)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.leading)
                                .padding(16)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .frame(height: 170)
            .clipped()

            // Card Footer — title + metadata
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // Q badge
                    Text("Q\(index + 1)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(tabColor)
                        .clipShape(Capsule())

                    Text(viewModel.problem.title)
                        .font(NSFont.heading)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)

                    Spacer()
                }

                // Status + step count
                HStack(spacing: 8) {
                    if viewModel.problemComplete {
                        Label("Solved", systemImage: "checkmark.circle.fill")
                            .font(NSFont.caption)
                            .foregroundStyle(Color.accentGreen)
                    } else if viewModel.validatedSteps.contains(where: { $0.isCorrect == false }) {
                        Label("Needs attention", systemImage: "exclamationmark.triangle.fill")
                            .font(NSFont.caption)
                            .foregroundStyle(Color.accentAmber)
                    } else if viewModel.validatedSteps.count > 0 {
                        Label("\(viewModel.validatedSteps.count) step\(viewModel.validatedSteps.count == 1 ? "" : "s")",
                              systemImage: "pencil.circle.fill")
                            .font(NSFont.caption)
                            .foregroundStyle(Color.accentBlue)
                    } else {
                        Text("Not started")
                            .font(NSFont.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer()

                    // Truncated first line of question
                    Text(viewModel.problem.statement.components(separatedBy: "\n").first ?? "")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color.textSecondary.opacity(0.6))
                        .lineLimit(1)
                        .frame(maxWidth: 120, alignment: .trailing)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.paperBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isHovered ? tabColor.opacity(0.6) : Color.blockBorder.opacity(0.5),
                    lineWidth: isHovered ? 2 : 1
                )
        )
        .cardShadow()
        .scaleEffect(isPressed ? 0.97 : (isHovered ? 1.02 : 1))
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovered)
        .animation(.spring(response: 0.15, dampingFraction: 0.8), value: isPressed)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            if isHovered {
                // Dismiss the description overlay
                withAnimation(.easeInOut(duration: 0.2)) { isHovered = false }
            } else {
                onTap()
            }
        }
        .onLongPressGesture(minimumDuration: 0.4) {
            // Toggle question description overlay for touch users
            withAnimation(.easeInOut(duration: 0.2)) { isHovered.toggle() }
        }
        .onAppear { generateThumbnail() }
        .onReceive(viewModel.$solutionData) { _ in generateThumbnail() }
    }

    // MARK: - Thumbnail Generation

    private func generateThumbnail() {
        guard let data = viewModel.solutionData,
              let drawing = try? PKDrawing(data: data),
              !drawing.bounds.isEmpty
        else {
            thumbnailImage = nil
            return
        }

        // Render the drawing at a small scale for the thumbnail
        let bounds = drawing.bounds
        let scale: CGFloat = min(280 / bounds.width, 160 / bounds.height, 2.0)
        let thumbnailSize = CGSize(
            width: bounds.width * scale,
            height: bounds.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: thumbnailSize))

            ctx.cgContext.scaleBy(x: scale, y: scale)
            ctx.cgContext.translateBy(x: -bounds.origin.x, y: -bounds.origin.y)

            let drawImage = drawing.image(from: bounds, scale: 2.0)
            drawImage.draw(in: bounds)
        }
        thumbnailImage = image
    }
}
