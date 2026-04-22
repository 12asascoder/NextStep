import Foundation

final class PersistenceService {
    static let shared = PersistenceService()
    
    private let defaults = UserDefaults.standard
    private let sessionsKey = "nextStep_savedSessions"
    
    private init() {}
    
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
    }
}
