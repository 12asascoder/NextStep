import SwiftUI

// MARK: - Subject List

private let availableSubjects = [
    "Mathematics", "Physics", "Chemistry", "Biology",
    "Computer Science", "Economics", "English", "Other (Custom)"
]

// MARK: - Canvas View (Notebook Style)

struct CanvasView: View {
    @ObservedObject var viewModel: CanvasViewModel
    @Environment(\.dismiss) private var dismiss

    // Local UI state
    @State private var isShowingAIPanel = false
    @State private var showSubjectPicker = false
    @State private var selectedSubject: String = ""
    @State private var showAIHintCard = false
    @State private var isSidebarVisible = false
    @State private var showCustomSubjectAlert = false
    @State private var tempCustomSubject = ""

    var body: some View {
        VStack(spacing: 0) {
            // ── Top Navigation Bar ──
            topNavigationBar

            // ── Main Content Area ──
            ZStack(alignment: .trailing) {
                // Warm cream background
                Color.notebookBg
                    .ignoresSafeArea()

                // Paper card area (always full width)
                paperCanvasArea
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                // AI Panel (overlays on the canvas, aligned trailing)
                if isShowingAIPanel {
                    aiInlinePanel
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .padding(.trailing, 16)
                        .padding(.vertical, 12)
                }

                // AI Hint Card (overlays on the canvas when visible)
                if showAIHintCard && !isShowingAIPanel {
                    aiHintCardPanel
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .padding(.trailing, 16)
                        .padding(.vertical, 12)
                }
            }
        }
        .background(Color.notebookBg.ignoresSafeArea())
        .navigationBarHidden(true)
        .alert("Custom Subject", isPresented: $showCustomSubjectAlert) {
            TextField("Enter custom subject", text: $tempCustomSubject)
            Button("OK") {
                if !tempCustomSubject.isEmpty {
                    selectedSubject = tempCustomSubject
                }
            }
            Button("Cancel", role: .cancel) {
                tempCustomSubject = ""
            }
        }
        // AI panel is now shown inline — no sheet needed
        .onChange(of: viewModel.aiPanelHint) { newHint in
            if !newHint.isEmpty {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showAIHintCard = true
                }
            }
        }
        .onAppear {
            PersistenceService.shared.startStudySession()
        }
        .onDisappear {
            PersistenceService.shared.endStudySession()
        }
    }

    // MARK: - Top Navigation Bar

    private var topNavigationBar: some View {
        HStack(spacing: 12) {
            // Back button + Title
            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.custom("Bradley Hand", size: 15))
                        .foregroundStyle(Color.navText)

                    Text(viewModel.problem.title)
                        .font(.custom("Bradley Hand", size: 17))
                        .foregroundStyle(Color.navText)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.navPillBg)
                )
            }
            .buttonStyle(.plain)

            Spacer()

            // Save Button
            Button(action: {
                PersistenceService.shared.saveUserProblem(viewModel.problem)
                NotificationCenter.default.post(name: Notification.Name("didCompleteProblemNotification"), object: nil)
            }) {
                Text("Save")
                    .font(.custom("Bradley Hand", size: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.accentBlue)
                    )
            }
            .buttonStyle(.plain)

            // Choose Subject button
            Button(action: { showSubjectPicker.toggle() }) {
                Text(selectedSubject.isEmpty ? "Choose Subject" : selectedSubject)
                    .font(.custom("Bradley Hand", size: 14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.navDarkPill)
                    )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showSubjectPicker, arrowEdge: .top) {
                subjectPickerPopover
            }

            // Sidebar toggle icon
            Button(action: { isSidebarVisible.toggle() }) {
                Image(systemName: "sidebar.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.navText)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.navPillBg)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.notebookBg)
    }

    // MARK: - Subject Picker Popover

    private var subjectPickerPopover: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(availableSubjects, id: \.self) { subject in
                Button(action: {
                    if subject == "Other (Custom)" {
                        showSubjectPicker = false
                        tempCustomSubject = "" // Clear previous input
                        showCustomSubjectAlert = true
                    } else {
                        selectedSubject = subject
                        showSubjectPicker = false
                    }
                }) {
                    HStack {
                        Text(subject)
                            .font(.custom("Bradley Hand", size: 15))
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        if selectedSubject == subject || (subject == "Other (Custom)" && !availableSubjects.contains(selectedSubject) && !selectedSubject.isEmpty) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color.accentBlue)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)

                if subject != availableSubjects.last {
                    Divider().padding(.horizontal, 12)
                }
            }
        }
        .frame(width: 220)
        .padding(.vertical, 4)
        .background(Color.paperCard)
    }

    // MARK: - Paper Canvas Area

    private var paperCanvasArea: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 0) {
                // Question text in handwriting style
                VStack(alignment: .leading, spacing: 0) {
                    // Question statement — distinct shade background
                        VStack(alignment: .leading, spacing: 0) {
                            TextField("Write your question here...", text: $viewModel.problem.statement, axis: .vertical)
                                .font(.custom("Bradley Hand", size: 19))
                                .foregroundStyle(Color.inkColor)
                                .tint(Color.accentBlue)
                                .lineSpacing(6)
                                .padding(.vertical, 20)
                                .padding(.horizontal, 24)
                                .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.questionAreaBg)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.paperBorder.opacity(0.5), lineWidth: 0.5)
                        )
                        .padding(.horizontal, 12)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                        // Solution area
                        if !viewModel.aiPanelHint.isEmpty {
                            Divider()
                                .background(Color.ruledLine)
                                .padding(.horizontal, 20)

                            // Display the solution in handwriting font
                            Text(formatSolutionText(viewModel.aiPanelHint))
                                .font(.custom("Bradley Hand", size: 17))
                                .foregroundStyle(Color.inkColor)
                                .lineSpacing(5)
                                .padding(.top, 16)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 24)
                        }

                        // PencilKit drawing canvas
                        PencilKitView(
                            canvasData: $viewModel.solutionData,
                            validatedSteps: viewModel.validatedSteps,
                            nextStepSuggestion: viewModel.nextStepSuggestion,
                            onStepTapped: nil,
                            onDataChange: { data in
                                viewModel.updateSolutionData(data)
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.paperWhite)
                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.paperBorder, lineWidth: 0.5)
            )

            // AI Hint Floating Button (top-right of paper card)
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    if isShowingAIPanel {
                        isShowingAIPanel = false
                    } else if showAIHintCard {
                        showAIHintCard = false
                    } else {
                        isShowingAIPanel = true
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.aiButtonBg)
                        .frame(width: 40, height: 40)

                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                }
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .padding(.trailing, 16)
        }
    }

    // MARK: - AI Hint Card Panel (floating on right)

    private var aiHintCardPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Next Step: Verify relationships")
                    .font(.custom("Bradley Hand", size: 14))
                    .foregroundStyle(Color.hintTitle)
                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        showAIHintCard = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.hintTitle.opacity(0.5))
                        .padding(6)
                        .background(Circle().fill(Color.hintTitle.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }

            // Hint content
            ScrollView {
                Text(LocalizedStringKey(formatHintContent(viewModel.aiPanelHint)))
                    .font(.custom("Bradley Hand", size: 13))
                    .foregroundStyle(Color.hintText)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .frame(width: 280)
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.hintCardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.hintCardBorder, lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: -4, y: 0)
    }

    // MARK: - Inline AI Panel (same blue card format as hint card)

    private var aiInlinePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("AI Assistant")
                    .font(.custom("Bradley Hand", size: 16))
                    .foregroundStyle(Color.hintTitle)
                Spacer()

                // Close button
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        isShowingAIPanel = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.hintTitle.opacity(0.5))
                        .padding(6)
                        .background(Circle().fill(Color.hintTitle.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }

            // Model badge
            HStack {
                Text("DeepSeek R1")
                    .font(.custom("Bradley Hand", size: 12))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentBlue.opacity(0.15))
                    .foregroundStyle(Color.accentBlue)
                    .clipShape(Capsule())

                Spacer()

                Text("Hints: \(viewModel.hintsUsed)")
                    .font(.custom("Bradley Hand", size: 12))
                    .foregroundStyle(Color.hintText.opacity(0.7))
            }

            Divider()
                .background(Color.hintCardBorder)

            // Content area
            if viewModel.cooldownRemaining > 0 {
                VStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.accentAmber)
                    Text("Take a moment to think.")
                        .font(.custom("Bradley Hand", size: 14))
                        .foregroundStyle(Color.hintTitle)
                    Text("Available in \(viewModel.cooldownRemaining)s")
                        .font(.custom("Bradley Hand", size: 16))
                        .foregroundStyle(Color.accentAmber)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else if viewModel.isLoadingAI {
                VStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(Color.accentBlue)
                    Text("Thinking…")
                        .font(.custom("Bradley Hand", size: 14))
                        .foregroundStyle(Color.hintText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !viewModel.aiPanelHint.isEmpty {
                ScrollView {
                    Text(LocalizedStringKey(formatHintContent(viewModel.aiPanelHint)))
                        .font(.custom("Bradley Hand", size: 13))
                        .foregroundStyle(Color.hintText)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.hintText.opacity(0.3))
                    Text("Need help? Tap below.")
                        .font(.custom("Bradley Hand", size: 14))
                        .foregroundStyle(Color.hintText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Spacer()

            // Action buttons
            VStack(spacing: 8) {
                Button { viewModel.requestAI(type: "hint") } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                        Text("Give me a Hint")
                            .font(.custom("Bradley Hand", size: 14))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentBlue)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                }

                Button { viewModel.requestAI(type: "next") } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right.circle")
                            .font(.system(size: 12))
                        Text("Next Step")
                            .font(.custom("Bradley Hand", size: 14))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentGreen)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                }

                Button { viewModel.requestFullSolution() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 12))
                        Text("Full Solution")
                            .font(.custom("Bradley Hand", size: 14))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentAmber)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoadingAI || viewModel.cooldownRemaining > 0)
            .opacity((viewModel.isLoadingAI || viewModel.cooldownRemaining > 0) ? 0.5 : 1)
        }
        .padding(16)
        .frame(width: 280)
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.hintCardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.hintCardBorder, lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: -4, y: 0)
    }

    // MARK: - Helpers

    private func formatSolutionText(_ text: String) -> String {
        let formatted = text
            .replacingOccurrences(of: "\\(", with: "")
            .replacingOccurrences(of: "\\)", with: "")
            .replacingOccurrences(of: "\\[", with: "")
            .replacingOccurrences(of: "\\]", with: "")
        return formatted
    }

    private func formatHintContent(_ text: String) -> String {
        let formatted = text
            .replacingOccurrences(of: "\\(", with: "")
            .replacingOccurrences(of: "\\)", with: "")
            .replacingOccurrences(of: "\\[", with: "")
            .replacingOccurrences(of: "\\]", with: "")
        return formatted
    }
}


