import SwiftUI

struct QuestionReviewView: View {
    @State var text: String
    var onConfirm: (String) -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Review Question")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .padding(.top)

                Text("Edit the text below if the scanner made any mistakes. If multiple questions were scanned, delete the ones you don't want to solve right now.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                TextEditor(text: $text)
                    .font(.system(size: 20, weight: .regular, design: .monospaced))
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                Button(action: {
                    onConfirm(text)
                }) {
                    Text("Start Solving")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.bottom)
            }
            .padding()
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
}
