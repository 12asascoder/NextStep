import SwiftUI
import PencilKit

// MARK: - PencilKitView (UIViewRepresentable)

/// Wraps PKCanvasView so it can be used inside SwiftUI.
struct PencilKitView: UIViewRepresentable {

    @Binding var canvasData: Data?

    var onDataChange: ((Data) -> Void)?

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isScrollEnabled = true
        canvas.isOpaque = false
        // Provide a huge content size to give the unbounded free canvas feel
        canvas.contentSize = CGSize(width: UIScreen.main.bounds.width, height: 10000)

        // Toolpicker
        let toolPicker = PKToolPicker()
        toolPicker.setVisible(true, forFirstResponder: canvas)
        toolPicker.addObserver(canvas)
        context.coordinator.toolPicker = toolPicker

        // Restore saved drawing
        if let data = canvasData,
           let drawing = try? PKDrawing(data: data) {
            canvas.drawing = drawing
        }

        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Only restore if binding changed externally (e.g. problem reset)
        if let data = canvasData,
           let drawing = try? PKDrawing(data: data),
           uiView.drawing.dataRepresentation() != data {
            uiView.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDataChange: onDataChange)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var onDataChange: ((Data) -> Void)?
        var toolPicker: PKToolPicker?
        var debounceTimer: Timer?

        init(onDataChange: ((Data) -> Void)?) {
            self.onDataChange = onDataChange
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            debounceTimer?.invalidate()
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                let data = canvasView.drawing.dataRepresentation()
                DispatchQueue.main.async {
                    self?.onDataChange?(data)
                }
            }
        }
    }
}
