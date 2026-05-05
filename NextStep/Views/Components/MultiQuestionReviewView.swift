import SwiftUI

/// Grid review screen shown after scanning detects multiple questions.
/// Users can edit, remove, or re-order questions before starting to solve them.
struct MultiQuestionReviewView: View {
    @State var questions: [String]
    var onConfirm: ([String]) -> Void
    var onCancel: () -> Void

    @State private var editingIndex: Int? = nil
    @State private var editText: String = ""

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Questions Found")
                        .font(.system(size: 32, weight: .bold, design: .serif))

                    Text("\(questions.count) question\(questions.count == 1 ? "" : "s") detected — tap to edit, swipe to remove")
                        .font(NSFont.body)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                .padding(.bottom, 24)
                .padding(.horizontal, 24)

                // Question Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                            QuestionCardView(
                                index: index,
                                text: question,
                                onEdit: {
                                    editText = question
                                    editingIndex = index
                                },
                                onRemove: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        if questions.indices.contains(index) {
                                            questions.remove(at: index)
                                        }
                                    }
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale(scale: 0.8).combined(with: .opacity)
                            ))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                Divider().background(Color.blockBorder)

                // Bottom Action Bar
                HStack(spacing: 16) {
                    Text("\(questions.count) question\(questions.count == 1 ? "" : "s")")
                        .font(NSFont.heading)
                        .foregroundStyle(Color.textSecondary)

                    Spacer()

                    Button(action: {
                        onConfirm(questions)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil.and.outline")
                            Text("Start Solving")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.accentBlue, Color.accentBlue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .cardShadow()
                    }
                    .buttonStyle(.plain)
                    .disabled(questions.isEmpty)
                    .opacity(questions.isEmpty ? 0.4 : 1)
                }
                .padding(24)
                .background(Color.paperBackground)
            }
            .background(Color.paperCard.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onCancel() }
                }
            }
            .sheet(isPresented: Binding(
                get: { editingIndex != nil },
                set: { if !$0 { editingIndex = nil } }
            )) {
                if let index = editingIndex {
                    QuestionEditSheet(
                        text: $editText,
                        onSave: {
                            if questions.indices.contains(index) {
                                questions[index] = editText
                            }
                            editingIndex = nil
                        },
                        onCancel: { editingIndex = nil }
                    )
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
            }
        }
    }
}


// MARK: - Question Card

struct QuestionCardView: View {
    let index: Int
    let text: String
    var onEdit: () -> Void
    var onRemove: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack {
                Text("Q\(index + 1)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(questionColor(for: index))
                    .clipShape(Capsule())

                Spacer()

                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.textSecondary.opacity(0.4))
                }
                .buttonStyle(.plain)
            }

            // Question text
            Text(text)
                .font(NSFont.body)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(6)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            // Edit button
            Button(action: onEdit) {
                HStack(spacing: 4) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                    Text("Edit")
                        .font(NSFont.caption)
                }
                .foregroundStyle(Color.accentBlue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentBlue.opacity(0.1))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        .background(Color.paperBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(questionColor(for: index).opacity(0.3), lineWidth: 1.5)
        )
        .cardShadow()
        .scaleEffect(isPressed ? 0.97 : 1)
        .onTapGesture { onEdit() }
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) { isPressed = pressing }
        }, perform: {})
    }

    private func questionColor(for index: Int) -> Color {
        let colors: [Color] = [.accentBlue, .accentGreen, .accentAmber, Color.purple]
        return colors[index % colors.count]
    }
}

// MARK: - Question Edit Sheet

struct QuestionEditSheet: View {
    @Binding var text: String
    var onSave: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Question")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .padding(.top, 24)

            TextEditor(text: $text)
                .font(.system(size: 18, weight: .regular, design: .monospaced))
                .padding(12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blockBorder, lineWidth: 1)
                )
                .padding(.horizontal, 24)

            HStack(spacing: 16) {
                Button("Cancel") { onCancel() }
                    .foregroundStyle(Color.textSecondary)

                Spacer()

                Button(action: onSave) {
                    Text("Save")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.accentBlue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(Color.paperCard.ignoresSafeArea())
    }
}
