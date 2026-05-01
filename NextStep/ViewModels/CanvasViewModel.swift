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

            var newValidatedSteps: [ValidatedStep] = []
            var oldSteps = self.validatedSteps

            // 1. Map OCR lines to existing steps or create new ones
            for line in lines {
                let normalised = line.text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !normalised.isEmpty, normalised.count > 1 else { continue }
                
                if let oldIndex = oldSteps.firstIndex(where: { line.canvasRect.intersects($0.canvasRect.insetBy(dx: -40, dy: -40)) }) {
                    var existingStep = oldSteps[oldIndex]
                    existingStep.canvasRect = line.canvasRect
                    if existingStep.text != normalised {
                        existingStep.text = normalised
                    }
                    newValidatedSteps.append(existingStep)
                    oldSteps.remove(at: oldIndex)
                } else {
                    let newStep = ValidatedStep(text: normalised, canvasRect: line.canvasRect, isCorrect: nil, feedback: "", isValidating: true)
                    newValidatedSteps.append(newStep)
                }
            }
            
            // 2. Determine where divergence starts (edits, insertions, or un-validated steps)
            var firstChangedIndex = newValidatedSteps.count
            for i in 0..<newValidatedSteps.count {
                if i >= self.validatedSteps.count || newValidatedSteps[i].text != self.validatedSteps[i].text {
                    firstChangedIndex = min(firstChangedIndex, i)
                    break
                }
            }
            
            // If steps were erased from the middle, divergence is at the mismatch point
            if self.validatedSteps.count > newValidatedSteps.count {
                for i in 0..<min(newValidatedSteps.count, self.validatedSteps.count) {
                    if newValidatedSteps[i].text != self.validatedSteps[i].text {
                        firstChangedIndex = min(firstChangedIndex, i)
                        break
                    }
                }
            }

            // 3. Mark all downstream steps as needing validation
            var needsBatchValidation = false
            for i in 0..<newValidatedSteps.count {
                if i >= firstChangedIndex || newValidatedSteps[i].isCorrect == nil {
                    newValidatedSteps[i].isCorrect = nil
                    newValidatedSteps[i].feedback = ""
                    newValidatedSteps[i].isValidating = true
                    needsBatchValidation = true
                }
            }
            
            self.validatedSteps = newValidatedSteps
            
            // 4. Fire a single batch validation request
            if needsBatchValidation && !newValidatedSteps.isEmpty {
                self.fireBatchValidation(for: newValidatedSteps)
            }
        }
    }
    
    private func fireBatchValidation(for steps: [ValidatedStep]) {
        let texts = steps.map { $0.text }
        
        Task {
            print("📡 Sending batch of \(texts.count) steps to backend for validation…")
            let results = await aiService.validateSteps(
                problem: problem.statement,
                steps: texts,
                difficulty: problem.difficulty,
                topic: problem.topic
            )
            
            guard let results = results else {
                print("⚠️ Batch validation failed.")
                for i in 0..<self.validatedSteps.count {
                    if self.validatedSteps[i].isValidating {
                        self.validatedSteps[i].isValidating = false
                    }
                }
                return
            }
            
            // Match results back to UI safely
            for result in results {
                let index = result.stepIndex
                if index >= 0 && index < self.validatedSteps.count {
                    if self.validatedSteps[index].text == texts[index] {
                        self.validatedSteps[index].isCorrect = result.isCorrect
                        self.validatedSteps[index].feedback = result.feedback
                        self.validatedSteps[index].isValidating = false
                        print("✅ Step \(index) [\"\(texts[index])\"] validated: correct=\(result.isCorrect)")
                    }
                }
            }
            
            // Clear any lingering validating flags (e.g. if backend returned fewer results)
            for i in 0..<self.validatedSteps.count {
                if self.validatedSteps[i].text == texts[i] {
                    self.validatedSteps[i].isValidating = false
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
