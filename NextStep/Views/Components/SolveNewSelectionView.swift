import SwiftUI

struct SolveNewSelectionView: View {
    @Environment(\.dismiss) var dismiss
    
    // Callbacks to ContentView
    var onProblemCreated: (MathProblem) -> Void
    
    // Internal routing state
    @State private var showingScanner = false
    @State private var showingWriteCanvas = false
    @State private var showingReview = false
    
    // Shared OCR text
    @State private var extractedText: String = ""
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
                        HStack {
                            Image(systemName: "camera.viewfinder")
                                .font(.title)
                            Text("Scan Document")
                                .font(.title2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    
                    Button(action: { showingWriteCanvas = true }) {
                        HStack {
                            Image(systemName: "pencil.and.outline")
                                .font(.title)
                            Text("Write Manually")
                                .font(.title2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 32)
                
                if isProcessingImage {
                    VStack {
                        ProgressView()
                        Text("Extracting Text...")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .padding(.top, 32)
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
        }
    }
    
    private func processScannedImage(_ image: UIImage) {
        isProcessingImage = true
        Task {
            let text = await TextRecognitionService.recognizeText(from: image)
            await MainActor.run {
                isProcessingImage = false
                extractedText = text
                // small delay to allow Scanner to dismiss
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showingReview = true
                }
            }
        }
    }
}
