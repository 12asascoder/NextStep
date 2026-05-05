import SwiftUI

struct SolveNewSelectionView: View {
    @Environment(\.dismiss) var dismiss
    
    // Callbacks to ContentView
    var onProblemCreated: (MathProblem) -> Void
    var onMultipleProblemsCreated: (([MathProblem]) -> Void)?
    
    // Internal routing state
    @State private var showingScanner = false
    @State private var showingWriteCanvas = false
    @State private var showingReview = false
    @State private var showingMultiReview = false
    
    // Shared OCR text
    @State private var extractedText: String = ""
    @State private var extractedQuestions: [String] = []
    @State private var isProcessingImage = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text("Solve a New Problem")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .padding(.top, 40)
                
                Text("How would you like to input the question?")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 20) {
                    Button(action: { showingScanner = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.viewfinder")
                                .font(.title)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Scan Document")
                                    .font(.title2)
                                Text("Auto-detects multiple questions")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.accentBlue, Color.accentBlue.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    
                    Button(action: { showingWriteCanvas = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "pencil.and.outline")
                                .font(.title)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Write Manually")
                                    .font(.title2)
                                Text("Draw or type your question")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.accentAmber, Color.accentAmber.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 32)
                
                if isProcessingImage {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.3)
                            .tint(Color.accentBlue)
                        Text("Scanning & extracting questions…")
                            .font(NSFont.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 32)
                    .transition(.opacity)
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                ScannerView { image in
                    processScannedImage(image)
                }
                .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showingWriteCanvas) {
                WriteQuestionView(onExtracted: { text in
                    self.showingWriteCanvas = false
                    self.extractedText = text
                    // small delay to allow WriteCanvas to dismiss before presenting Review
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.showingReview = true
                    }
                }, onCancel: {
                    self.showingWriteCanvas = false
                })
            }
            // Single question review (from Write Manually or single-question scan)
            .fullScreenCover(isPresented: $showingReview) {
                QuestionReviewView(text: extractedText, onConfirm: { finalText in
                    self.showingReview = false
                    let newProblem = MathProblem(
                        title: "Custom Problem",
                        statement: finalText,
                        difficulty: "10th Grade",
                        topic: "General Math"
                    )
                    onProblemCreated(newProblem)
                    dismiss()
                }, onCancel: {
                    self.showingReview = false
                })
            }
            // Multi-question review (from scanner detecting 2+ questions)
            .fullScreenCover(isPresented: $showingMultiReview) {
                MultiQuestionReviewView(
                    questions: extractedQuestions,
                    onConfirm: { confirmedQuestions in
                        self.showingMultiReview = false
                        
                        if confirmedQuestions.count == 1 {
                            // Single question — use existing flow
                            let problem = MathProblem(
                                title: "Scanned Problem",
                                statement: confirmedQuestions[0],
                                difficulty: "10th Grade",
                                topic: "General Math"
                            )
                            onProblemCreated(problem)
                        } else {
                            // Multiple questions — create batch
                            let problems = confirmedQuestions.enumerated().map { index, text in
                                MathProblem(
                                    title: "Question \(index + 1)",
                                    statement: text,
                                    difficulty: "10th Grade",
                                    topic: "General Math"
                                )
                            }
                            onMultipleProblemsCreated?(problems)
                        }
                        dismiss()
                    },
                    onCancel: {
                        self.showingMultiReview = false
                    }
                )
            }
        }
    }
    
    private func processScannedImage(_ image: UIImage) {
        isProcessingImage = true
        Task {
            let questions = await TextRecognitionService.extractQuestions(from: image)
            await MainActor.run {
                isProcessingImage = false
                
                if questions.count >= 2 {
                    // Multiple questions detected — show multi-question review
                    extractedQuestions = questions
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showingMultiReview = true
                    }
                } else {
                    // Single question — use existing review flow
                    extractedText = questions.first ?? ""
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showingReview = true
                    }
                }
            }
        }
    }
}
