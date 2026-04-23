import Foundation

// MARK: - API Request / Response Models

struct HintRequestBody: Codable {
    let problem: String
    let studentWork: String?
    let hintType: String
    let conversationHistory: [[String: String]]?
    let difficulty: String?
    let topic: String?

    enum CodingKeys: String, CodingKey {
        case problem
        case studentWork = "student_work"
        case hintType = "hint_type"
        case conversationHistory = "conversation_history"
        case difficulty
        case topic
    }
}

struct ValidateStepRequestBody: Codable {
    let problem: String
    let stepText: String
    let previousSteps: [String]?
    let difficulty: String?
    let topic: String?

    enum CodingKeys: String, CodingKey {
        case problem
        case stepText = "step_text"
        case previousSteps = "previous_steps"
        case difficulty
        case topic
    }
}

struct FullSolutionRequestBody: Codable {
    let problem: String
    let difficulty: String?
    let topic: String?
}

struct AIResponseBody: Codable {
    let response: String
    let reasoning: String?
    let isCorrect: Bool?
    let hintType: String

    enum CodingKeys: String, CodingKey {
        case response
        case reasoning
        case isCorrect = "is_correct"
        case hintType = "hint_type"
    }
}

// MARK: - AI Service

@MainActor
final class AIService {

    // ⚠️ Change this to your Mac's local IP if running on a real device.
    // Use "localhost" for Simulator only.
    static let baseURL = "http://localhost:8000"

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120  // DeepSeek R1 can take time to reason
        config.timeoutIntervalForResource = 180
        return URLSession(configuration: config)
    }()

    // MARK: - Hint / Next Step / Reflect

    func executeHint(
        problem: String,
        type: String,
        studentWork: String? = nil,
        conversationHistory: [[String: String]]? = nil,
        difficulty: String? = "10th Grade",
        topic: String? = nil
    ) async -> String {
        let body = HintRequestBody(
            problem: problem,
            studentWork: studentWork,
            hintType: type,
            conversationHistory: conversationHistory,
            difficulty: difficulty,
            topic: topic
        )

        do {
            let result: AIResponseBody = try await post(endpoint: "/ai/hint", body: body)
            return result.response
        } catch {
            print("❌ AIService.executeHint failed: \(error)")
            return "Sorry, I couldn't connect to the AI server. Please check your connection and try again."
        }
    }

    // MARK: - Validate a Solution Step

    func validateStep(
        problem: String,
        stepText: String,
        previousSteps: [String]? = nil,
        difficulty: String? = "10th Grade",
        topic: String? = nil
    ) async -> (isCorrect: Bool?, feedback: String) {
        let body = ValidateStepRequestBody(
            problem: problem,
            stepText: stepText,
            previousSteps: previousSteps,
            difficulty: difficulty,
            topic: topic
        )

        do {
            let result: AIResponseBody = try await post(endpoint: "/ai/validate", body: body)
            return (result.isCorrect, result.response)
        } catch {
            print("❌ AIService.validateStep failed: \(error)")
            return (nil, "Could not validate — AI server unreachable.")
        }
    }

    // MARK: - Full Solution

    func getFullSolution(
        problem: String,
        difficulty: String? = "10th Grade",
        topic: String? = nil
    ) async -> String {
        let body = FullSolutionRequestBody(
            problem: problem,
            difficulty: difficulty,
            topic: topic
        )

        do {
            let result: AIResponseBody = try await post(endpoint: "/ai/solution", body: body)
            return result.response
        } catch {
            print("❌ AIService.getFullSolution failed: \(error)")
            return "Sorry, I couldn't fetch the solution. Please try again."
        }
    }

    // MARK: - Generic POST Helper

    private func post<T: Codable, R: Codable>(endpoint: String, body: T) async throws -> R {
        guard let url = URL(string: "\(AIService.baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        let (data, httpResponse) = try await session.data(for: request)

        if let http = httpResponse as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("⚠️ Server returned \(http.statusCode): \(errorBody)")
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(R.self, from: data)
    }
}
