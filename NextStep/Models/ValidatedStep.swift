import Foundation

/// Tracks a single recognised solution step and its AI validation state.
struct ValidatedStep: Identifiable {
    let id = UUID()
    var text: String
    /// Position of this step in canvas-point coordinates.
    var canvasRect: CGRect
    /// `nil` while still waiting for AI.  `true` = correct, `false` = incorrect.
    var isCorrect: Bool? = nil
    /// Human-readable feedback from DeepSeek R1.
    var feedback: String = ""
    /// Whether we are currently waiting for the backend.
    var isValidating: Bool = true
    /// If the AI found an error, the corrected version of this step.
    var correctedStep: String? = nil
    /// The suggested next step (shown inline below the last correct step).
    var nextStepHint: String? = nil
}
