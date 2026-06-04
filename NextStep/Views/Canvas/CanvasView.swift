import SwiftUI

// MARK: - Subject List

private let availableSubjects = [
    "Mathematics", "Physics", "Chemistry", "Biology",
    "Computer Science", "Economics", "English"
]

// MARK: - Canvas View (Notebook Style)

struct CanvasView: View {
    @ObservedObject var viewModel: CanvasViewModel
    @Environment(\.dismiss) private var dismiss

    // Local UI state
    @State private var isShowingAIPopup = false
    @State private var isEditingQuestion = false
    @State private var showSubjectPicker = false
    @State private var selectedSubject: String = ""
    @State private var showAIHintCard = false
    @State private var activeInputMode: InputMode = .write
    @State private var isSidebarVisible = false

    enum InputMode: String, CaseIterable {
        case type = "Type"
        case write = "Write"
        case scan = "Scan"

        var icon: String {
            switch self {
            case .type: return "keyboard"
            case .write: return "pencil.tip"
            case .scan: return "camera"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Top Navigation Bar ──
            topNavigationBar

            // ── Main Content Area ──
            ZStack {
                // Warm cream background
                Color.notebookBg
                    .ignoresSafeArea()

                HStack(spacing: 0) {
                    // Paper card area
                    paperCanvasArea
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                    // AI Hint Card (floating on the right when visible)
                    if showAIHintCard {
                        aiHintCardPanel
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                            .padding(.trailing, 16)
                            .padding(.vertical, 12)
                    }
                }
            }

            // ── Bottom Toolbar ──
            bottomToolbar
        }
        .background(Color.notebookBg.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $isEditingQuestion) {
            QuestionEditView(
                statement: viewModel.problem.statement,
                onSave: { newText in
                    viewModel.problem.statement = newText
                    isEditingQuestion = false
                },
                onCancel: {
                    isEditingQuestion = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingAIPopup) {
            AIPanelView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
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
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.navText)

                    Text(viewModel.problem.title)
                        .font(.system(size: 17, weight: .semibold))
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

            // Choose Subject button
            Button(action: { showSubjectPicker.toggle() }) {
                Text(selectedSubject.isEmpty ? "Choose Subject" : selectedSubject)
                    .font(.system(size: 14, weight: .medium))
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
                    selectedSubject = subject
                    showSubjectPicker = false
                }) {
                    HStack {
                        Text(subject)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        if selectedSubject == subject {
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
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Question statement
                        Text(viewModel.problem.statement)
                            .font(.custom("Bradley Hand", size: 19))
                            .foregroundStyle(Color.inkColor)
                            .lineSpacing(6)
                            .padding(.top, 24)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)

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
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 500)
                    }
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
                if showAIHintCard {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        showAIHintCard = false
                    }
                } else {
                    isShowingAIPopup = true
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
                    .font(.system(size: 14, weight: .semibold))
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
                    .font(.system(size: 13, weight: .regular))
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
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack(spacing: 0) {
            // Input mode buttons (Type, Write, Scan)
            HStack(spacing: 0) {
                ForEach(InputMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            activeInputMode = mode
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 13, weight: .medium))
                            Text(mode.rawValue)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(Color.toolbarBtnText)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(activeInputMode == mode
                                      ? Color.toolbarBtnActiveBg
                                      : Color.toolbarBtnBg)
                        )
                    }
                    .buttonStyle(.plain)

                    if mode != InputMode.allCases.last {
                        Rectangle()
                            .fill(Color.toolbarDivider)
                            .frame(width: 1, height: 24)
                    }
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.toolbarGroupBg)
            )

            Spacer()

            // Solve button
            Button(action: {
                // Trigger AI solve
                viewModel.requestAI(type: "next")
            }) {
                Text("Solve")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.solveBtnBg)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.notebookBg)
    }

    // MARK: - Helpers

    private func formatSolutionText(_ text: String) -> String {
        var formatted = text
            .replacingOccurrences(of: "\\(", with: "")
            .replacingOccurrences(of: "\\)", with: "")
            .replacingOccurrences(of: "\\[", with: "")
            .replacingOccurrences(of: "\\]", with: "")
        return formatted
    }

    private func formatHintContent(_ text: String) -> String {
        var formatted = text
            .replacingOccurrences(of: "\\(", with: "")
            .replacingOccurrences(of: "\\)", with: "")
            .replacingOccurrences(of: "\\[", with: "")
            .replacingOccurrences(of: "\\]", with: "")
        return formatted
    }
}

// MARK: - Inline Question Editor

/// Sheet for editing the question text directly.
struct QuestionEditView: View {
    @State var statement: String
    var onSave: (String) -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Cancel") { onCancel() }
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Text("Edit Question")
                    .font(NSFont.heading)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Button("Save") {
                    onSave(statement)
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.accentBlue)
                .disabled(statement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            TextEditor(text: $statement)
                .font(.system(size: 20, weight: .regular, design: .monospaced))
                .padding(12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blockBorder, lineWidth: 1)
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .background(Color.paperCard.ignoresSafeArea())
    }
}
