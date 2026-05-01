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

        // Render the drawing to a bitmap with padding and a white background
        let scale: CGFloat = 2.0
        let padding: CGFloat = 20.0
        let renderBounds = bounds.insetBy(dx: -padding, dy: -padding)
        
        let traitCollection = UITraitCollection(userInterfaceStyle: .light)
        let format = UIGraphicsImageRendererFormat(for: traitCollection)
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(bounds: renderBounds, format: format)
        
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(renderBounds)
            
            let drawingImage = drawing.image(from: renderBounds, scale: scale)
            drawingImage.draw(at: renderBounds.origin)
        }
        
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
                    let x = renderBounds.origin.x + vBox.origin.x * renderBounds.width
                    let y = renderBounds.origin.y + (1 - vBox.origin.y - vBox.height) * renderBounds.height
                    let w = vBox.width * renderBounds.width
                    let h = vBox.height * renderBounds.height

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

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }

    // MARK: - Image Text Recognition (Solve New)
    
    /// Recognise text from a static image (e.g. from camera scanner)
    /// Returns the concatenated raw text.
    static func recognizeText(from image: UIImage) async -> String {
        // Redraw image to fix orientation and guarantee a cgImage exists
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        let normalizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        
        guard let cgImage = normalizedImage.cgImage else { return "" }
        
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNRecognizedTextObservation]
                else {
                    continuation.resume(returning: "")
                    return
                }
                
                let lines: [String] = observations.compactMap { obs in
                    guard let candidate = obs.topCandidates(1).first,
                          candidate.confidence > 0.15
                    else { return nil }
                    return candidate.string
                }
                
                // For a scanned document, just join lines with newlines
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            
            // Typical document scans might have orientation, but VNImageRequestHandler can infer if we pass it,
            // or we just rely on standard orientation.
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }
}
