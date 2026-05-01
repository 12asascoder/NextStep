import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CanvasViewModel()
    @State private var navigationPath = NavigationPath()
    @State private var showSolveNew = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                HStack {
                    Text("Sums")
                        .font(.system(size: 40, weight: .bold, design: .serif))
                    Spacer()
                    Button(action: { showSolveNew = true }) {
                        Text("Solve\nNew")
                            .font(.system(size: 18, weight: .medium, design: .serif))
                            .multilineTextAlignment(.trailing)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 40)
                .padding(.bottom, 24)

                List(MathProblem.samples) { problem in
                    NavigationLink(value: problem) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(problem.title)
                                .font(NSFont.heading)
                                .foregroundStyle(Color.textPrimary)
                            Text(problem.statement)
                                .font(NSFont.body)
                                .lineLimit(2)
                                .foregroundStyle(Color.textSecondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.paperBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 8)
                }
                .listStyle(.plain)
            }
            .background(Color.paperCard.ignoresSafeArea())
            .navigationDestination(for: MathProblem.self) { problem in
                CanvasView(viewModel: viewModel)
                    .onAppear {
                        viewModel.loadProblem(problem)
                    }
            }
            .sheet(isPresented: $showSolveNew) {
                SolveNewSelectionView(onProblemCreated: { newProblem in
                    navigationPath.append(newProblem)
                })
            }
        }
    }
}
