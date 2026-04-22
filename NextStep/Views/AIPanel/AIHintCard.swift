import SwiftUI

struct AIHintCard: View {
    let hint: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.accentBlue)
                Text("AI Suggestion")
                    .font(NSFont.heading)
                    .foregroundStyle(Color.accentBlue)
            }

            Text(hint)
                .font(NSFont.body)
                .foregroundStyle(Color.textPrimary)
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.accentBlue.opacity(0.2), lineWidth: 1)
                )
        )
        .softShadow()
    }
}
