import SwiftUI

struct AIPanelView: View {
    @ObservedObject var viewModel: CanvasViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Header with Cognitive State
            VStack(spacing: 8) {
                HStack {
                    Text("AI Assistant")
                        .font(NSFont.title)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                }
                
                HStack {
                    Text("Independence: \(viewModel.independenceScore)%")
                        .font(NSFont.caption)
                        .foregroundStyle(viewModel.independenceScore > 50 ? Color.accentGreen : Color.accentAmber)
                    Spacer()
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            // Dynamic State Messaging
            if viewModel.helpDecision == .block {
                VStack(spacing: 12) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.blockedAccent)
                    Text(viewModel.helpDecision.message)
                        .font(NSFont.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.textPrimary)
                    Text("Complete the next step independently.")
                        .font(NSFont.caption)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(24)
                .background(Color.blockedStateBg)
                .cornerRadius(16)
                .padding(.horizontal, 24)
            } else if viewModel.cooldownRemaining > 0 {
                VStack(spacing: 12) {
                    Image(systemName: "timer")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.accentAmber)
                    Text("Take a moment to think.")
                        .font(NSFont.body)
                        .foregroundStyle(Color.textPrimary)
                    Text("Available in \(viewModel.cooldownRemaining)s")
                        .font(NSFont.heading)
                        .foregroundStyle(Color.accentAmber)
                }
                .padding(24)
                .background(Color.paperCard)
                .cornerRadius(16)
                .padding(.horizontal, 24)
            } else if viewModel.isLoadingAI {
                VStack(spacing: 16) {
                    ProgressView().scaleEffect(1.5).tint(Color.accentBlue)
                    Text("Thinking...").font(NSFont.body).foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !viewModel.aiPanelHint.isEmpty {
                ScrollView {
                    Text(viewModel.aiPanelHint)
                        .font(NSFont.body)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.paperCard)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                }
            } else {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile").font(.system(size: 48)).foregroundStyle(Color.textSecondary.opacity(0.3))
                    Text("AI is available to assist.").font(NSFont.body).foregroundStyle(Color.textSecondary)
                }
                Spacer()
            }

            Spacer()

            // Safe Interaction Buttons
            VStack(spacing: 12) {
                Button { viewModel.requestAI(type: "hint") } label: {
                    Label("Give me a Hint", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentBlue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                
                Button { viewModel.requestAI(type: "next") } label: {
                    Label("Next Step", systemImage: "arrow.right.circle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentGreen)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                
                Button { viewModel.requestAI(type: "reflect") } label: {
                    Label("Reflect", systemImage: "questionmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.textSecondary)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoadingAI || viewModel.helpDecision == .block || viewModel.cooldownRemaining > 0)
            .opacity((viewModel.isLoadingAI || viewModel.helpDecision == .block || viewModel.cooldownRemaining > 0) ? 0.5 : 1)
            .padding(24)
        }
        .background(Color.aiPanelBg)
        .overlay(Rectangle().fill(Color.blockBorder).frame(width: 1), alignment: .leading)
    }
}
