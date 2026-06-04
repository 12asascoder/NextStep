import SwiftUI

/// Inline AI hint card that appears floating over/beside the paper canvas.
/// Matches the light-blue panel design from the reference images.
struct AIHintCard: View {
    let title: String
    let hint: String
    var onDismiss: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack(alignment: .top) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.hintTitle)

                Spacer()

                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.hintTitle.opacity(0.5))
                            .padding(5)
                            .background(
                                Circle()
                                    .fill(Color.hintTitle.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Hint body content
            Text(formattedHint(hint))
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.hintText)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.hintCardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.hintCardBorder, lineWidth: 0.5)
        )
    }

    private func formattedHint(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "\\(", with: "")
            .replacingOccurrences(of: "\\)", with: "")
            .replacingOccurrences(of: "\\[", with: "")
            .replacingOccurrences(of: "\\]", with: "")
    }
}
