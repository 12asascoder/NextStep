import SwiftUI

struct AIPanelView: View {
    @ObservedObject var viewModel: CanvasViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Text("AI Assistant")
                        .font(NSFont.title)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Text("DeepSeek R1")
                        .font(NSFont.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.accentBlue.opacity(0.15))
                        .foregroundStyle(Color.accentBlue)
                        .clipShape(Capsule())
                }

                HStack {
                    Text("Independence: \(viewModel.independenceScore)%")
                        .font(NSFont.caption)
                        .foregroundStyle(viewModel.independenceScore > 50 ? Color.accentGreen : Color.accentAmber)
                    Spacer()
                    Text("Hints used: \(viewModel.hintsUsed)")
                        .font(NSFont.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            // Content area
            if viewModel.cooldownRemaining > 0 {
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
                    Text("DeepSeek R1 is thinking…")
                        .font(NSFont.body)
                        .foregroundStyle(Color.textSecondary)
                    Text("The reasoning model may take a moment.")
                        .font(NSFont.caption)
                        .foregroundStyle(Color.textSecondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !viewModel.aiPanelHint.isEmpty {
                ScrollView {
                    Text(LocalizedStringKey(formattedAIResponse(viewModel.aiPanelHint)))
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
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.textSecondary.opacity(0.3))
                    Text("Need help? Tap a button below.")
                        .font(NSFont.body)
                        .foregroundStyle(Color.textSecondary)
                    Text("Steps are validated automatically on the canvas.")
                        .font(NSFont.caption)
                        .foregroundStyle(Color.textSecondary.opacity(0.5))
                }
                Spacer()
            }

            Spacer()

            // Buttons: Hint & Solution only
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

                Button { viewModel.requestFullSolution() } label: {
                    Label("Full Solution", systemImage: "doc.text.magnifyingglass")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentAmber)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoadingAI || viewModel.cooldownRemaining > 0)
            .opacity((viewModel.isLoadingAI || viewModel.cooldownRemaining > 0) ? 0.5 : 1)
            .padding(24)
        }
        .background(Color.aiPanelBg)
        .overlay(Rectangle().fill(Color.blockBorder).frame(width: 1), alignment: .leading)
    }

    private func formattedAIResponse(_ text: String) -> String {
        // Remove common LaTeX delimiters that DeepSeek R1 uses
        // Replace \( and \) with nothing or a slight space for better readability in Markdown
        var formatted = text
            .replacingOccurrences(of: "\\(", with: "")
            .replacingOccurrences(of: "\\)", with: "")
            .replacingOccurrences(of: "\\[", with: "")
            .replacingOccurrences(of: "\\]", with: "")
        return formatted
    }
}
