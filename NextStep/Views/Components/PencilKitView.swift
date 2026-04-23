import SwiftUI
import PencilKit

// MARK: - PencilKitView (UIViewRepresentable)

/// Wraps PKCanvasView so it can be used inside SwiftUI.
/// Renders inline validation icons (✓ / ⚠) on the canvas for each recognised step.
struct PencilKitView: UIViewRepresentable {

    @Binding var canvasData: Data?
    /// Validated steps to show icons for — driven by the ViewModel.
    var validatedSteps: [ValidatedStep]
    /// Called when a validation icon is tapped.
    var onStepTapped: ((ValidatedStep) -> Void)?

    var onDataChange: ((Data) -> Void)?

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isScrollEnabled = true
        canvas.isOpaque = false
        canvas.contentSize = CGSize(width: UIScreen.main.bounds.width, height: 10000)

        // Toolpicker
        let toolPicker = PKToolPicker()
        toolPicker.setVisible(true, forFirstResponder: canvas)
        toolPicker.addObserver(canvas)
        context.coordinator.toolPicker = toolPicker
        context.coordinator.canvasView = canvas

        // Restore saved drawing
        if let data = canvasData,
           let drawing = try? PKDrawing(data: data) {
            canvas.drawing = drawing
        }

        // Tap gesture for validation icon interaction
        // A quick tap does NOT conflict with drawing strokes (which require drag)
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleCanvasTap(_:))
        )
        tapGesture.numberOfTapsRequired = 1
        tapGesture.cancelsTouchesInView = false
        canvas.addGestureRecognizer(tapGesture)

        // Make canvas first responder so tool picker shows up
        DispatchQueue.main.async {
            canvas.becomeFirstResponder()
        }

        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Restore if binding changed externally (e.g. problem reset)
        if let data = canvasData,
           let drawing = try? PKDrawing(data: data),
           uiView.drawing.dataRepresentation() != data {
            uiView.drawing = drawing
            context.coordinator.clearValidationIcons()
        }

        // Update validation icons on canvas
        context.coordinator.updateValidationIcons(
            steps: validatedSteps,
            onTap: onStepTapped
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDataChange: onDataChange)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var onDataChange: ((Data) -> Void)?
        var toolPicker: PKToolPicker?
        var debounceTimer: Timer?
        weak var canvasView: PKCanvasView?

        // Validation icon tracking
        private var iconViews: [UIView] = []
        /// Maps icon tag → (step, callback)
        private var stepLookup: [Int: (ValidatedStep, ((ValidatedStep) -> Void)?)] = [:]
        private let iconTagBase = 9000
        /// Track what's currently rendered to avoid unnecessary rebuilds
        private var renderedStepIDs: Set<UUID> = []

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

        // MARK: - Tap Handling

        @objc func handleCanvasTap(_ gesture: UITapGestureRecognizer) {
            guard let canvas = canvasView else { return }
            let tapPoint = gesture.location(in: canvas)

            // Check if the tap landed on or near a validation icon
            for iconView in iconViews {
                // Expand the hit area slightly for easier tapping
                let hitArea = iconView.frame.insetBy(dx: -12, dy: -12)
                if hitArea.contains(tapPoint) {
                    if let (step, callback) = stepLookup[iconView.tag] {
                        // Pulse feedback animation
                        UIView.animate(withDuration: 0.1, animations: {
                            iconView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                        }) { _ in
                            UIView.animate(withDuration: 0.1) {
                                iconView.transform = .identity
                            }
                        }
                        callback?(step)
                    }
                    return
                }
            }
        }

        // MARK: - Validation Icon Management

        func clearValidationIcons() {
            for v in iconViews { v.removeFromSuperview() }
            iconViews.removeAll()
            stepLookup.removeAll()
            renderedStepIDs.removeAll()
        }

        func updateValidationIcons(steps: [ValidatedStep], onTap: ((ValidatedStep) -> Void)?) {
            guard let canvas = canvasView else { return }

            // Build set of current step IDs + validation states
            let currentState = steps.map { "\($0.id)-\($0.isValidating)-\(String(describing: $0.isCorrect))" }
            let currentHash = currentState.joined()
            let renderedHash = renderedStepIDs.map { $0.uuidString }.sorted().joined()

            // Quick check: if step count matches and IDs haven't changed, skip full rebuild
            // But always rebuild if any validation state changed
            let newIDs = Set(steps.map { $0.id })
            let needsRebuild = newIDs != renderedStepIDs || steps.contains(where: { step in
                iconViews.first(where: { $0.tag == iconTagBase + (steps.firstIndex(where: { $0.id == step.id }) ?? 0) }) == nil
            }) || steps.contains(where: { !$0.isValidating && !renderedStepIDs.isEmpty })

            // Always rebuild for simplicity — the icon count is small
            for v in iconViews { v.removeFromSuperview() }
            iconViews.removeAll()
            stepLookup.removeAll()
            renderedStepIDs = newIDs

            let iconSize: CGFloat = 36

            for (index, step) in steps.enumerated() {
                let tag = iconTagBase + index
                let iconView = buildIconView(for: step, size: iconSize)
                iconView.tag = tag

                // Position: right of the recognised text, vertically centred
                let xPos = step.canvasRect.maxX + 20
                let yPos = step.canvasRect.midY - iconSize / 2

                iconView.frame = CGRect(x: xPos, y: yPos, width: iconSize, height: iconSize)
                canvas.addSubview(iconView)
                iconViews.append(iconView)
                stepLookup[tag] = (step, onTap)

                // Animate in for newly completed validations
                if !step.isValidating {
                    iconView.alpha = 0
                    iconView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
                    UIView.animate(
                        withDuration: 0.45,
                        delay: Double(index) * 0.05,
                        usingSpringWithDamping: 0.6,
                        initialSpringVelocity: 0.8
                    ) {
                        iconView.alpha = 1
                        iconView.transform = .identity
                    }
                }
            }
        }

        // MARK: - Build Icon Views

        private func buildIconView(for step: ValidatedStep, size: CGFloat) -> UIView {
            let container = UIView(frame: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
            container.backgroundColor = UIColor.systemBackground
            container.layer.cornerRadius = size / 2
            container.layer.shadowColor = UIColor.black.cgColor
            container.layer.shadowOpacity = 0.15
            container.layer.shadowRadius = 6
            container.layer.shadowOffset = CGSize(width: 0, height: 2)
            container.isUserInteractionEnabled = false // taps handled by gesture recognizer

            if step.isValidating {
                // Spinner
                let spinner = UIActivityIndicatorView(style: .medium)
                spinner.color = UIColor.systemBlue
                spinner.startAnimating()
                spinner.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(spinner)
                NSLayoutConstraint.activate([
                    spinner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                    spinner.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                ])
            } else {
                // Result symbol
                let isCorrect = step.isCorrect ?? false
                let symbolName = isCorrect ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                let color = isCorrect ? UIColor.systemGreen : UIColor.systemOrange

                let imageView = UIImageView()
                let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
                imageView.image = UIImage(systemName: symbolName, withConfiguration: config)
                imageView.tintColor = color
                imageView.contentMode = .scaleAspectFit
                imageView.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(imageView)
                NSLayoutConstraint.activate([
                    imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                    imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                    imageView.widthAnchor.constraint(equalToConstant: 24),
                    imageView.heightAnchor.constraint(equalToConstant: 24),
                ])

                // Tint the container background based on result
                container.backgroundColor = isCorrect
                    ? UIColor.systemGreen.withAlphaComponent(0.1)
                    : UIColor.systemOrange.withAlphaComponent(0.1)
                container.layer.borderWidth = 2
                container.layer.borderColor = color.withAlphaComponent(0.4).cgColor
            }

            return container
        }
    }
}
