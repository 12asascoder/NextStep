import SwiftUI

struct CanvasView: View {
    @ObservedObject var viewModel: CanvasViewModel
    @State private var isShowingAIPopup = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // MAIN CANVAS AREA (100% Free Form)
            VStack(alignment: .leading, spacing: 0) {
                // Fixed Question Header
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        Text("Q")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        
                        Button {
                            print("--- SCANNED QUESTION ---")
                            print(viewModel.problem.statement)
                            print("------------------------")
                        } label: {
                            HStack {
                                Image(systemName: "viewfinder")
                                Text("Scan / Write")
                            }
                            .font(NSFont.caption)
                            .foregroundStyle(Color.accentBlue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentBlue.opacity(0.1), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    Text(viewModel.problem.statement)
                        .font(NSFont.math)
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 24)
                .background(Color.paperBackground)
                
                Divider().background(Color.blockBorder)

                // Free Scrollable PencilKit Canvas Region
                ZStack(alignment: .topLeading) {
                    DotGridBackground()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Soln")
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundStyle(Color.textPrimary)
                            .padding(.horizontal, 40)
                            .padding(.top, 16)
                            
                        PencilKitView(
                            canvasData: $viewModel.solutionData,
                            onDataChange: { data in
                                viewModel.updateSolutionData(data)
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Floating AI Assistant Button
            Button {
                isShowingAIPopup = true
            } label: {
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(20)
                    .background(Color.accentBlue, in: Circle())
                    .shadow(color: Color.accentBlue.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(32)
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $isShowingAIPopup) {
            AIPanelView(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
