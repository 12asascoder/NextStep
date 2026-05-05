import SwiftUI
import PencilKit

// MARK: - PencilKitView (UIViewRepresentable)

/// Wraps PKCanvasView so it can be used inside SwiftUI.
/// Renders inline validation icons (✓ / ⚠) on the canvas for each recognised step.
struct PencilKitView: UIViewRepresentable {

    @Binding var canvasData: Data?
    /// Validated steps to show icons for — driven by the ViewModel.
    var validatedSteps: [ValidatedStep]
    /// Next-step suggestion to render inline below the last step.
    var nextStepSuggestion: String?
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
            nextStepSuggestion: nextStepSuggestion,
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
        /// Inline hint/correction labels
        private var labelViews: [UIView] = []
        /// Maps icon tag → (step, callback)
        private var stepLookup: [Int: (ValidatedStep, ((ValidatedStep) -> Void)?)] = [:]
        private let iconTagBase = 9000
        private let labelTagBase = 8000
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
            for v in labelViews { v.removeFromSuperview() }
            labelViews.removeAll()
            stepLookup.removeAll()
            renderedStepIDs.removeAll()
        }

        func updateValidationIcons(steps: [ValidatedStep], nextStepSuggestion: String? = nil, onTap: ((ValidatedStep) -> Void)?) {
            guard let canvas = canvasView else { return }

            // Always rebuild for simplicity — the icon count is small
            for v in iconViews { v.removeFromSuperview() }
            iconViews.removeAll()
            for v in labelViews { v.removeFromSuperview() }
            labelViews.removeAll()
            stepLookup.removeAll()
            let newIDs = Set(steps.map { $0.id })
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

                // Corrected step label (shown below error steps)
                if step.isCorrect == false, let corrected = step.correctedStep {
                    let label = buildInlineLabel(
                        text: "→ \(corrected)",
                        color: UIColor.systemGreen,
                        bgColor: UIColor.systemGreen.withAlphaComponent(0.08)
                    )
                    let labelX = step.canvasRect.minX
                    let labelY = step.canvasRect.maxY + 6
                    label.frame = CGRect(x: labelX, y: labelY, width: min(label.intrinsicContentSize.width + 24, 400), height: 28)
                    label.tag = labelTagBase + index
                    canvas.addSubview(label)
                    labelViews.append(label)

                    // Fade in
                    label.alpha = 0
                    UIView.animate(withDuration: 0.3, delay: 0.2) {
                        label.alpha = 1
                    }
                }
            }

            // Next-step hint label (below the last step)
            if let suggestion = nextStepSuggestion, !suggestion.isEmpty, let lastStep = steps.last {
                let label = buildInlineLabel(
                    text: "→ Next: \(suggestion)",
                    color: UIColor.systemBlue,
                    bgColor: UIColor.systemBlue.withAlphaComponent(0.06)
                )
                let labelX = lastStep.canvasRect.minX
                let labelY = lastStep.canvasRect.maxY + 12
                label.frame = CGRect(x: labelX, y: labelY, width: min(label.intrinsicContentSize.width + 24, 500), height: 30)
                label.tag = labelTagBase + 999
                canvas.addSubview(label)
                labelViews.append(label)

                // Slide in animation
                label.alpha = 0
                label.transform = CGAffineTransform(translationX: -20, y: 0)
                UIView.animate(withDuration: 0.4, delay: 0.3, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
                    label.alpha = 0.9
                    label.transform = .identity
                }
            }
        }

        // MARK: - Build Inline Label

        private func buildInlineLabel(text: String, color: UIColor, bgColor: UIColor) -> PaddedLabel {
            let label = PaddedLabel()
            label.edgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
            label.text = text
            label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            label.textColor = color
            label.backgroundColor = bgColor
            label.layer.cornerRadius = 8
            label.layer.masksToBounds = true
            label.textAlignment = .left
            label.sizeToFit()
            return label
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

// MARK: - Padded UILabel

/// A UILabel subclass that supports internal edge insets for padding.
class PaddedLabel: UILabel {
    var edgeInsets = UIEdgeInsets.zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: edgeInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + edgeInsets.left + edgeInsets.right,
            height: size.height + edgeInsets.top + edgeInsets.bottom
        )
    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetBounds = bounds.inset(by: edgeInsets)
        let textRect = super.textRect(forBounds: insetBounds, limitedToNumberOfLines: numberOfLines)
        return textRect
    }
}
