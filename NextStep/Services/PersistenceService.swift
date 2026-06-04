import Foundation

final class PersistenceService {
    static let shared = PersistenceService()
    
    private let defaults = UserDefaults.standard
    private let sessionsKey = "nextStep_savedSessions"
    private let streakKey   = "nextStep_streakDays"
    private let lastUsedKey = "nextStep_lastUsedDate"
    private let studyTimeKey = "nextStep_studyTimeSeconds"
    private let sessionStartKey = "nextStep_sessionStartDate"
    
    private init() {}
    
    // MARK: - Learning Sessions
    
    func saveSession(_ session: LearningSession) {
        var allSessions = loadAllSessions()
        if let idx = allSessions.firstIndex(where: { $0.problemID == session.problemID }) {
            allSessions[idx] = session
        } else {
            allSessions.append(session)
        }
        
        if let encoded = try? JSONEncoder().encode(allSessions) {
            defaults.set(encoded, forKey: sessionsKey)
        }
    }
    
    func loadAllSessions() -> [LearningSession] {
        guard let data = defaults.data(forKey: sessionsKey),
              let sessions = try? JSONDecoder().decode([LearningSession].self, from: data) else {
            return []
        }
        return sessions
    }
    
    func loadSession(for problemID: UUID) -> LearningSession? {
        return loadAllSessions().first(where: { $0.problemID == problemID })
    }
    
    func clearAll() {
        defaults.removeObject(forKey: sessionsKey)
        defaults.removeObject(forKey: streakKey)
        defaults.removeObject(forKey: lastUsedKey)
        defaults.removeObject(forKey: studyTimeKey)
        defaults.removeObject(forKey: sessionStartKey)
    }
    
    // MARK: - Aggregate Independence Score
    
    /// Computes the average independence score across all saved sessions.
    /// Returns 0 if no sessions exist (fresh install).
    var aggregateIndependenceScore: Int {
        let sessions = loadAllSessions()
        guard !sessions.isEmpty else { return 0 }
        let total = sessions.reduce(0) { $0 + $1.independenceScore }
        return total / sessions.count
    }
    
    /// Total hints used across all sessions.
    var totalHintsUsed: Int {
        return loadAllSessions().reduce(0) { $0 + $1.hintsUsed }
    }
    
    // MARK: - Streak Tracking
    
    /// Call this when the user opens the app or starts a solving session.
    /// Updates the streak counter based on consecutive calendar days.
    func recordAppUsage() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastUsedDate = defaults.object(forKey: lastUsedKey) as? Date {
            let lastDay = calendar.startOfDay(for: lastUsedDate)
            let dayDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if dayDiff == 0 {
                // Same day — streak stays the same, nothing to update
                return
            } else if dayDiff == 1 {
                // Next consecutive day — increment streak
                let currentStreak = defaults.integer(forKey: streakKey)
                defaults.set(currentStreak + 1, forKey: streakKey)
            } else {
                // Gap of 2+ days — reset streak to 1
                defaults.set(1, forKey: streakKey)
            }
        } else {
            // First ever usage — start streak at 1
            defaults.set(1, forKey: streakKey)
        }
        
        defaults.set(today, forKey: lastUsedKey)
    }
    
    /// Current streak days. Returns 0 if the app has never been used.
    var currentStreak: Int {
        let streak = defaults.integer(forKey: streakKey) // defaults to 0
        
        // If there's a saved streak but the user hasn't opened for 2+ days, it's stale
        if let lastUsedDate = defaults.object(forKey: lastUsedKey) as? Date {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let lastDay = calendar.startOfDay(for: lastUsedDate)
            let dayDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if dayDiff > 1 {
                // Streak is broken — return 0 (will be reset to 1 on next recordAppUsage)
                return 0
            }
        }
        
        return streak
    }
    
    // MARK: - Study Time Tracking
    
    /// Call when the user starts a solving session.
    func startStudySession() {
        defaults.set(Date(), forKey: sessionStartKey)
    }
    
    /// Call when the user ends a solving session (navigates away, app backgrounds, etc.).
    func endStudySession() {
        guard let startDate = defaults.object(forKey: sessionStartKey) as? Date else { return }
        let elapsed = Date().timeIntervalSince(startDate)
        let currentTotal = defaults.double(forKey: studyTimeKey) // defaults to 0.0
        defaults.set(currentTotal + elapsed, forKey: studyTimeKey)
        defaults.removeObject(forKey: sessionStartKey)
    }
    
    /// Total study time in seconds across all sessions.
    var totalStudyTimeSeconds: TimeInterval {
        var total = defaults.double(forKey: studyTimeKey)
        
        // If there's an active session, include its elapsed time
        if let startDate = defaults.object(forKey: sessionStartKey) as? Date {
            total += Date().timeIntervalSince(startDate)
        }
        
        return total
    }
    
    /// Formatted study time string (e.g., "0min", "45min", "2h 15min")
    var formattedStudyTime: String {
        let totalSeconds = Int(totalStudyTimeSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
}
