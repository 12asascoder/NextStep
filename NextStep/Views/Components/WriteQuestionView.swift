import SwiftUI
import PencilKit

/// Single-screen question input that combines handwriting canvas and text editing.
/// The user can either type directly, or draw with Apple Pencil and tap "Extract" to
/// populate the text field. No second review screen needed.
struct WriteQuestionView: View {
    @State private var canvasData: Data? = nil
    @State private var questionText: String = ""
    @State private var isExtracting = false
    @State private var showCanvas = false
    
    var onExtracted: (String) -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Title
                Text("Enter Your Question")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                Text("Type below or use the drawing canvas")
                    .font(NSFont.caption)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.bottom, 16)

                // Text Editor — always visible, user can type directly
                TextEditor(text: $questionText)
                    .font(.system(size: 20, weight: .regular, design: .monospaced))
                    .padding(12)
                    .frame(minHeight: 120, maxHeight: showCanvas ? 120 : .infinity)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blockBorder, lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if questionText.isEmpty {
                            Text("Type your math question here…")
                                .font(.system(size: 20, design: .monospaced))
                                .foregroundStyle(Color.textSecondary.opacity(0.4))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(.horizontal, 20)

                // Toggle to show/hide drawing canvas
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showCanvas.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showCanvas ? "chevron.up" : "scribble")
                            .font(.system(size: 14, weight: .semibold))
                        Text(showCanvas ? "Hide Drawing Canvas" : "Draw with Apple Pencil")
                            .font(NSFont.caption)
                    }
                    .foregroundStyle(Color.accentBlue)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                // Drawing Canvas (collapsible)
                if showCanvas {
                    VStack(spacing: 8) {
                        PencilKitView(
                            canvasData: $canvasData,
                            validatedSteps: [],
                            onStepTapped: nil,
                            onDataChange: { data in
                                self.canvasData = data
                            }
                        )
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blockBorder, lineWidth: 1)
                        )
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal, 20)

                        // Extract text button
                        Button(action: extractText) {
                            HStack(spacing: 8) {
                                if isExtracting {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "text.viewfinder")
                                    Text("Extract Text from Drawing")
                                }
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule().fill(Color.accentBlue)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isExtracting || canvasData == nil)
                        .opacity(canvasData == nil ? 0.4 : 1)
                        .padding(.bottom, 8)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Divider().background(Color.blockBorder).padding(.top, 4)

                // Start Solving button
                Button(action: {
                    onExtracted(questionText.trimmingCharacters(in: .whitespacesAndNewlines))
                }) {
                    Text("Start Solving")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color.gray
                                : Color.accentBlue
                        )
                        .cornerRadius(12)
                }
                .disabled(questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
    
    private func extractText() {
        guard let data = canvasData, let drawing = try? PKDrawing(data: data) else { return }
        isExtracting = true
        
        Task {
            let lines = await TextRecognitionService.recognizeText(from: drawing)
            let text = lines.map { $0.text }.joined(separator: "\n")
            
            await MainActor.run {
                isExtracting = false
                if !text.isEmpty {
                    // Append extracted text to whatever the user has already typed
                    if questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        questionText = text
                    } else {
                        questionText += "\n" + text
                    }
                }
            }
        }
    }
}
