import SwiftUI
import PencilKit

struct WriteQuestionView: View {
    @State private var canvasData: Data? = nil
    @State private var isProcessing = false
    
    var onExtracted: (String) -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                Text("Write Your Question")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .padding(.top)
                
                PencilKitView(
                    canvasData: $canvasData,
                    validatedSteps: [],
                    onStepTapped: nil,
                    onDataChange: { data in
                        self.canvasData = data
                    }
                )
                .background(Color.white)
                .cornerRadius(12)
                .padding()
                
                Button(action: processDrawing) {
                    HStack {
                        if isProcessing {
                            ProgressView().tint(.white)
                        } else {
                            Text("Extract Text")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(isProcessing || canvasData == nil)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
    
    private func processDrawing() {
        guard let data = canvasData, let drawing = try? PKDrawing(data: data) else { return }
        isProcessing = true
        
        Task {
            let lines = await TextRecognitionService.recognizeText(from: drawing)
            let text = lines.map { $0.text }.joined(separator: "\n")
            
            await MainActor.run {
                isProcessing = false
                onExtracted(text)
            }
        }
    }
}
