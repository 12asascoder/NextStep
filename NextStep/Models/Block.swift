import Foundation

// MARK: - Math Problem

struct MathProblem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let title: String
    let statement: String
    let difficulty: String
    let topic: String

    init(id: UUID = UUID(), title: String, statement: String, difficulty: String = "10th Grade", topic: String) {
        self.id = id
        self.title = title
        self.statement = statement
        self.difficulty = difficulty
        self.topic = topic
    }
}

// MARK: - Session Data Layer

struct LearningSession: Codable, Identifiable {
    let id: UUID
    let problemID: UUID
    var solutionData: Data?      // Free Canvas PKDrawing serialized data
    var independenceScore: Int
    var hintsUsed: Int
    let date: Date
    
    init(id: UUID = UUID(), problemID: UUID, solutionData: Data? = nil, independenceScore: Int, hintsUsed: Int, date: Date = Date()) {
        self.id = id
        self.problemID = problemID
        self.solutionData = solutionData
        self.independenceScore = independenceScore
        self.hintsUsed = hintsUsed
        self.date = date
    }
}

// MARK: - Sample Problems

extension MathProblem {
    static let samples: [MathProblem] = [
        MathProblem(
            title: "Quadratic Equation",
            statement: "Solve for x:\n2x² + 5x − 12 = 0",
            topic: "Algebra"
        ),
        MathProblem(
            title: "Linear Systems",
            statement: "Find x and y:\n3x + 2y = 12\nx − y = 1",
            topic: "Algebra"
        ),
        MathProblem(
            title: "Geometry – Circle",
            statement: "A circle has radius 7 cm.\nFind the area and circumference. (Use π = 3.14)",
            topic: "Geometry"
        )
    ]
}
