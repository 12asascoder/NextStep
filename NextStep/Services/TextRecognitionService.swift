import Foundation
import Vision
import PencilKit
import UIKit

// MARK: - Recognised line from OCR

struct RecognizedLine: Identifiable, Equatable {
    let id = UUID()
    let text: String
    /// Bounding rectangle expressed in **canvas-point** coordinates.
    let canvasRect: CGRect
    let confidence: Float

    static func == (lhs: RecognizedLine, rhs: RecognizedLine) -> Bool {
        lhs.text == rhs.text
    }
}

// MARK: - Vision-based text recognition

final class TextRecognitionService {

    /// Recognise handwritten text inside a `PKDrawing`.
    ///
    /// - Returns: An array of `RecognizedLine` with positions in the
    ///   canvas coordinate space so they can be used to place overlays.
    static func recognizeText(from drawing: PKDrawing) async -> [RecognizedLine] {
        let bounds = drawing.bounds
        guard !bounds.isEmpty, bounds.width > 1, bounds.height > 1 else { return [] }

        // Render the drawing to a bitmap
        let scale: CGFloat = 2.0
        let image = drawing.image(from: bounds, scale: scale)
        guard let cgImage = image.cgImage else { return [] }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation]
                else {
                    continuation.resume(returning: [])
                    return
                }

                let lines: [RecognizedLine] = observations.compactMap { obs in
                    guard let candidate = obs.topCandidates(1).first,
                          candidate.confidence > 0.15
                    else { return nil }

                    // Vision bounding box: normalised (0-1), origin bottom-left.
                    // Convert to canvas coordinates.
                    let vBox = obs.boundingBox
                    let x = bounds.origin.x + vBox.origin.x * bounds.width
                    let y = bounds.origin.y + (1 - vBox.origin.y - vBox.height) * bounds.height
                    let w = vBox.width * bounds.width
                    let h = vBox.height * bounds.height

                    return RecognizedLine(
                        text: candidate.string,
                        canvasRect: CGRect(x: x, y: y, width: w, height: h),
                        confidence: candidate.confidence
                    )
                }

                // Sort top-to-bottom
                let sorted = lines.sorted { $0.canvasRect.midY < $1.canvasRect.midY }
                continuation.resume(returning: sorted)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false  // math doesn't benefit

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }
}
