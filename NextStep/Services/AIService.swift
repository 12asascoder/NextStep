import Foundation

@MainActor
final class AIService {
    func executeHint(problem: String, type: String) async -> String {
        let delay = UInt64.random(in: 400_000_000...800_000_000)
        try? await Task.sleep(nanoseconds: delay)
        
        switch type {
        case "hint":
            return "Have you tried looking for a common denominator or isolating the variable?"
        case "next":
            return "Try to expand the terms on the left hand side first."
        case "reflect":
            return "What would happen if we plugged 0 into this equation?"
        default:
            return "Try simplifying the expression."
        }
    }
}
