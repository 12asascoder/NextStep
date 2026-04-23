import SwiftUI

struct CanvasView: View {
    @ObservedObject var viewModel: CanvasViewModel
    @State private var isShowingAIPopup = false
    @State private var selectedStep: ValidatedStep? = nil
    @State private var showFeedback = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // MAIN CANVAS AREA (100% Free Form)
            VStack(alignment: .leading, spacing: 0) {
                // Fixed Question Header
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        Text("Q")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        
                        // Live validation count badge
                        if !viewModel.validatedSteps.isEmpty {
                            let correct = viewModel.validatedSteps.filter { $0.isCorrect == true }.count
                            let wrong = viewModel.validatedSteps.filter { $0.isCorrect == false }.count
                            let pending = viewModel.validatedSteps.filter { $0.isValidating }.count
                            
                            HStack(spacing: 8) {
                                if correct > 0 {
                                    Label("\(correct)", systemImage: "checkmark.circle.fill")
                                        .font(NSFont.caption)
                                        .foregroundStyle(Color.accentGreen)
                                }
                                if wrong > 0 {
                                    Label("\(wrong)", systemImage: "exclamationmark.triangle.fill")
                                        .font(NSFont.caption)
                                        .foregroundStyle(Color.accentAmber)
                                }
                                if pending > 0 {
                                    Label("\(pending)", systemImage: "clock.fill")
                                        .font(NSFont.caption)
                                        .foregroundStyle(Color.accentBlue)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.paperCard, in: Capsule())
                        }
                        
                        Button {
                            print("--- SCANNED QUESTION ---")
                            print(viewModel.problem.statement)
                            print("------------------------")
                        } label: {
                            HStack {
                                Image(systemName: "viewfinder")
                                Text("Scan / Write")
                            }
                            .font(NSFont.caption)
                            .foregroundStyle(Color.accentBlue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentBlue.opacity(0.1), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    Text(viewModel.problem.statement)
                        .font(NSFont.math)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 24)
                .background(Color.paperBackground)
                
                Divider().background(Color.blockBorder)

                // Free Scrollable PencilKit Canvas Region
                ZStack(alignment: .topLeading) {
                    DotGridBackground()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Soln")
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundStyle(Color.textPrimary)
                            .padding(.horizontal, 40)
                            .padding(.top, 16)
                            
                        PencilKitView(
                            canvasData: $viewModel.solutionData,
                            validatedSteps: viewModel.validatedSteps,
                            onStepTapped: { step in
                                selectedStep = step
                                showFeedback = true
                            },
                            onDataChange: { data in
                                viewModel.updateSolutionData(data)
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Floating AI Assistant Button
            Button {
                isShowingAIPopup = true
            } label: {
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(20)
                    .background(Color.accentBlue, in: Circle())
                    .shadow(color: Color.accentBlue.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(32)
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $isShowingAIPopup) {
            AIPanelView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showFeedback) {
            if let step = selectedStep {
                StepFeedbackSheet(step: step)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Step Feedback Sheet

/// Rich feedback sheet shown when the student taps a validation icon.
struct StepFeedbackSheet: View {
    let step: ValidatedStep

    var body: some View {
        VStack(spacing: 20) {
            // Status icon
            if step.isValidating {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding(.top, 24)
                Text("Checking your step…")
                    .font(NSFont.heading)
                    .foregroundStyle(Color.textPrimary)
            } else if let isCorrect = step.isCorrect {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(isCorrect ? Color.accentGreen : Color.accentAmber)
                    .padding(.top, 24)

                Text(isCorrect ? "Correct!" : "Needs Attention")
                    .font(NSFont.title)
                    .foregroundStyle(Color.textPrimary)
            }

            // The student's step text
            VStack(alignment: .leading, spacing: 8) {
                Text("Your step:")
                    .font(NSFont.caption)
                    .foregroundStyle(Color.textSecondary)
                Text(step.text)
                    .font(NSFont.math)
                    .foregroundStyle(Color.textPrimary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.paperBackground)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 24)

            // AI feedback
            if !step.feedback.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Color.accentBlue)
                        Text("AI Feedback")
                            .font(NSFont.heading)
                            .foregroundStyle(Color.accentBlue)
                    }
                    Text(step.feedback)
                        .font(NSFont.body)
                        .foregroundStyle(Color.textPrimary)
                        .lineSpacing(4)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.aiPanelBg)
                .cornerRadius(12)
                .padding(.horizontal, 24)
            }

            Spacer()
        }
        .background(Color.paperCard.ignoresSafeArea())
    }
}
