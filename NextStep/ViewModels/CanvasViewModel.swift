import SwiftUI
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
    
    // Cognitive Cooldown
    @Published var cooldownRemaining: Int = 0
    private var cooldownTimer: Timer?

    // Independence Tracking
    @Published var independenceScore: Int = 100
    @Published var hintsUsed: Int = 0
    
    private let aiService = AIService()
    private let persistence = PersistenceService.shared

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
        cooldownTimer?.invalidate()
        setupInitialWorkspace()
    }

    func updateSolutionData(_ data: Data) {
        self.solutionData = data
        autoSave()
    }

    // MARK: - Pedagogy & Cognitive Engines
    
    // Unconstrained Free Canvas means we don't strictly alternate blocks.
    // They are evaluated purely on hints used.
    
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

    // MARK: - Safely Wrapped AI Method

    func requestAI(type: String) {
        guard helpDecision == .allow, cooldownRemaining == 0 else { return }

        isLoadingAI = true
        aiPanelHint = ""

        Task {
            let hint = await aiService.executeHint(problem: problem.statement, type: type)
            await MainActor.run {
                self.aiPanelHint = hint
                self.isLoadingAI = false
                
                self.hintsUsed += 1
                self.updateIndependenceScore()
                self.startCooldown()
                self.autoSave()
            }
        }
    }
}
