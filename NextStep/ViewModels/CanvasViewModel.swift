import SwiftUI
import PencilKit
import Combine

enum HelpDecision {
    case allow
    case block

    var message: String {
        switch self {
        case .allow: return "AI can offer guidance."
        case .block: return "Try solving this step yourself."
        }
    }
}

@MainActor
final class CanvasViewModel: ObservableObject {

    @Published var problem: MathProblem
    @Published var solutionData: Data?

    // AI & Pedagogy State
    @Published var helpDecision: HelpDecision = .allow
    @Published var isLoadingAI: Bool = false
    @Published var aiPanelHint: String = ""

    // Auto-validation state  — drives the inline icons on the canvas
    @Published var validatedSteps: [ValidatedStep] = []
    /// Texts already sent for validation so we don't re-send.
    private var validatedTexts: Set<String> = []

    // Cognitive Cooldown
    @Published var cooldownRemaining: Int = 0
    private var cooldownTimer: Timer?

    // Independence Tracking
    @Published var independenceScore: Int = 100
    @Published var hintsUsed: Int = 0

    // Conversation history
    private var conversationHistory: [[String: String]] = []

    private let aiService = AIService()
    private let persistence = PersistenceService.shared

    // OCR debounce
    private var ocrTask: Task<Void, Never>?

    init(problem: MathProblem = MathProblem.samples[0]) {
        self.problem = problem
        setupInitialWorkspace()
    }

    private func setupInitialWorkspace() {
        if let savedSession = persistence.loadSession(for: problem.id) {
            self.solutionData = savedSession.solutionData
            self.independenceScore = savedSession.independenceScore
            self.hintsUsed = savedSession.hintsUsed
        } else {
            self.solutionData = nil
            self.hintsUsed = 0
            self.independenceScore = 100
            self.cooldownRemaining = 0
            autoSave()
        }
    }

    func loadProblem(_ p: MathProblem) {
        problem = p
        aiPanelHint = ""
        isLoadingAI = false
        validatedSteps = []
        validatedTexts = []
        conversationHistory = []
        cooldownTimer?.invalidate()
        ocrTask?.cancel()
        setupInitialWorkspace()
    }

    func updateSolutionData(_ data: Data) {
        self.solutionData = data
        autoSave()
        // Trigger auto-validation OCR (debounced)
        triggerAutoValidation()
    }

    // MARK: - Auto Validation via OCR

    private func triggerAutoValidation() {
        ocrTask?.cancel()
        ocrTask = Task {
            // Debounce: wait 2 seconds after last stroke before running OCR
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }

            guard let data = solutionData,
                  let drawing = try? PKDrawing(data: data)
            else {
                print("⏭️  No drawing data to OCR")
                return
            }

            print("🔍 Running OCR on drawing (bounds: \(drawing.bounds))")
            let lines = await TextRecognitionService.recognizeText(from: drawing)
            guard !Task.isCancelled else { return }

            print("📝 OCR found \(lines.count) line(s): \(lines.map { $0.text })")

            // Collect previously validated texts for context
            let previousTexts = validatedSteps.compactMap { step -> String? in
                guard step.isCorrect != nil else { return nil }
                return step.text
            }

            for line in lines {
                let normalised = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !normalised.isEmpty,
                      normalised.count > 1,  // skip single characters
                      !validatedTexts.contains(normalised)
                else { continue }

                validatedTexts.insert(normalised)
                print("🆕 New step to validate: \"\(normalised)\"")

                // Add a "validating" placeholder immediately so the spinner shows
                let placeholder = ValidatedStep(
                    text: normalised,
                    canvasRect: line.canvasRect,
                    isCorrect: nil,
                    feedback: "",
                    isValidating: true
                )
                validatedSteps.append(placeholder)
                let stepIndex = validatedSteps.count - 1

                // Fire-and-forget validation call to backend
                Task {
                    print("📡 Sending step \(stepIndex) to backend for validation…")
                    let result = await aiService.validateStep(
                        problem: problem.statement,
                        stepText: normalised,
                        previousSteps: previousTexts,
                        difficulty: problem.difficulty,
                        topic: problem.topic
                    )

                    guard stepIndex < validatedSteps.count else { return }
                    validatedSteps[stepIndex].isCorrect = result.isCorrect
                    validatedSteps[stepIndex].feedback = result.feedback
                    validatedSteps[stepIndex].isValidating = false
                    print("✅ Step \(stepIndex) validated: correct=\(String(describing: result.isCorrect))")
                }
            }
        }
    }

    // MARK: - Pedagogy & Cognitive Engines

    private func updateIndependenceScore() {
        let newScore = 100 - (hintsUsed * 10)
        independenceScore = max(0, min(100, newScore))
    }

    private func startCooldown() {
        cooldownRemaining = 5
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else { return }
                if self.cooldownRemaining > 0 {
                    self.cooldownRemaining -= 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }

    // MARK: - Storage

    private func autoSave() {
        let session = LearningSession(
            problemID: problem.id,
            solutionData: solutionData,
            independenceScore: independenceScore,
            hintsUsed: hintsUsed
        )
        persistence.saveSession(session)
    }

    // MARK: - AI Hint / Solution (AI Panel only)

    func requestAI(type: String) {
        guard helpDecision == .allow, cooldownRemaining == 0 else { return }

        isLoadingAI = true
        aiPanelHint = ""

        Task {
            let hint = await aiService.executeHint(
                problem: problem.statement,
                type: type,
                conversationHistory: conversationHistory.isEmpty ? nil : conversationHistory,
                difficulty: problem.difficulty,
                topic: problem.topic
            )

            self.aiPanelHint = hint
            self.isLoadingAI = false

            conversationHistory.append(["role": "user", "content": "Give me a \(type) for: \(problem.statement)"])
            conversationHistory.append(["role": "assistant", "content": hint])

            hintsUsed += 1
            updateIndependenceScore()
            startCooldown()
            autoSave()
        }
    }

    func requestFullSolution() {
        isLoadingAI = true
        aiPanelHint = ""

        Task {
            let solution = await aiService.getFullSolution(
                problem: problem.statement,
                difficulty: problem.difficulty,
                topic: problem.topic
            )

            self.aiPanelHint = solution
            self.isLoadingAI = false
            hintsUsed += 3
            updateIndependenceScore()
            autoSave()
        }
    }
}
