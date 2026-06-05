import SwiftUI

struct AnalysisView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Top header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left.circle")
                                .font(.system(size: 20))
                            Text("Analysis")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.92, green: 0.9, blue: 0.86))
                        )
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // 1. No. of problems solved in one week
                VStack(alignment: .leading, spacing: 20) {
                    Text("No. of problems solved in one week")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.black.opacity(0.7))
                    
                    HStack(alignment: .bottom, spacing: 0) {
                        barColumn(height: 60, label: "Mon")
                        barColumn(height: 90, label: "Tue")
                        barColumn(height: 30, label: "Wed")
                        barColumn(height: 50, label: "Thur")
                        barColumn(height: 20, label: "Fri")
                        barColumn(height: 35, label: "Sat")
                        barColumn(height: 80, label: "Sun")
                    }
                    .frame(height: 140)
                    
                    // Simple x-axis line
                    Rectangle()
                        .fill(Color.black.opacity(0.2))
                        .frame(height: 1)
                        .padding(.horizontal, 12)
                }
                .padding(24)
                .background(Color(red: 0.98, green: 0.97, blue: 0.95))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.1), lineWidth: 1))
                .padding(.horizontal, 24)

                // 2 & 3. Pie Charts (Accuracy & Subject)
                HStack(spacing: 20) {
                    // Accuracy
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Accuracy Distribution")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.black.opacity(0.7))
                        
                        HStack(spacing: 16) {
                            pieChart(colors: [Color.ringGreen, Color(red: 0.95, green: 0.4, blue: 0.4), Color.ringYellow], portions: [0.5, 0.3, 0.2])
                                .frame(width: 100, height: 100)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                legendItem(color: Color.ringGreen, label: "Correct")
                                legendItem(color: Color(red: 0.95, green: 0.4, blue: 0.4), label: "Incorrect")
                                legendItem(color: Color.ringYellow, label: "Skipped")
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.98, green: 0.97, blue: 0.95))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.1), lineWidth: 1))

                    // Subject
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Subject Distribution")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.black.opacity(0.7))
                        
                        HStack(spacing: 16) {
                            pieChart(colors: [Color.ringGreen, Color(red: 0.95, green: 0.4, blue: 0.6), Color.ringYellow, Color.ringBlue], portions: [0.15, 0.1, 0.45, 0.3])
                                .frame(width: 100, height: 100)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                legendItem(color: Color.ringGreen, label: "Maths", value: "35%")
                                legendItem(color: Color(red: 0.95, green: 0.4, blue: 0.6), label: "Bio", value: "15%")
                                legendItem(color: Color.ringYellow, label: "Chemistry", value: "60%")
                                legendItem(color: Color.ringBlue, label: "Calculus", value: "45%")
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.98, green: 0.97, blue: 0.95))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.1), lineWidth: 1))
                }
                .padding(.horizontal, 24)

                // 4 & 5. Topics and Hints
                HStack(alignment: .top, spacing: 20) {
                    // Recommended Next Topics
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Recommended Next Topics")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.black.opacity(0.7))
                            Text("Based on your recent performance, these topics are\nrecommended to help you improve faster.")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.black.opacity(0.5))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        topicCard(icon: "pencil", color: Color(red: 0.95, green: 0.4, blue: 0.4), title: "Practice Logarithms", questions: "5 Questions")
                        topicCard(icon: "flask.fill", color: Color.ringGreen, title: "Halo-alkanes Numericals", questions: "5 Questions")
                        topicCard(icon: "book.closed.fill", color: Color.ringBlue, title: "Review Trigonometry Identities", questions: "5 Questions")
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.98, green: 0.97, blue: 0.95))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.1), lineWidth: 1))

                    // Hints Used vs. Problem Solved
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Hints Used vs. Problem Solved")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.black.opacity(0.7))
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                legendItem(color: Color(red: 0.7, green: 0.9, blue: 0.7), label: "Independent Solving")
                                legendItem(color: Color(red: 0.95, green: 0.6, blue: 0.6), label: "Guided")
                            }
                        }
                        
                        // Stacked Bar Chart
                        HStack(alignment: .bottom, spacing: 0) {
                            stackedBarColumn(indep: 40, guided: 30, label: "Mon")
                            stackedBarColumn(indep: 45, guided: 20, label: "Tue")
                            stackedBarColumn(indep: 25, guided: 25, label: "Wed")
                            stackedBarColumn(indep: 35, guided: 25, label: "Thur")
                            stackedBarColumn(indep: 20, guided: 35, label: "Fri")
                            stackedBarColumn(indep: 25, guided: 10, label: "Sat")
                            stackedBarColumn(indep: 50, guided: 30, label: "Sun")
                        }
                        .frame(height: 160)
                        .padding(.top, 8)
                        
                        // Simple x-axis line
                        Rectangle()
                            .fill(Color.black.opacity(0.2))
                            .frame(height: 1)
                            .padding(.horizontal, 12)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.98, green: 0.97, blue: 0.95))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.1), lineWidth: 1))
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 60)
            }
        }
        .background(Color(red: 0.96, green: 0.94, blue: 0.88).ignoresSafeArea())
    }

    private func barColumn(height: CGFloat, label: String) -> some View {
        VStack(spacing: 8) {
            Spacer()
            Rectangle()
                .fill(Color(red: 0.7, green: 0.9, blue: 0.7))
                .frame(width: 44, height: height)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    private func stackedBarColumn(indep: CGFloat, guided: CGFloat, label: String) -> some View {
        VStack(spacing: 8) {
            Spacer()
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color(red: 0.95, green: 0.6, blue: 0.6))
                    .frame(width: 32, height: guided)
                    .cornerRadius(16, corners: [.topLeft, .topRight])
                Rectangle()
                    .fill(Color(red: 0.7, green: 0.9, blue: 0.7))
                    .frame(width: 32, height: indep)
            }
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    private func pieChart(colors: [Color], portions: [Double]) -> some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            var startAngle = Angle.zero
            
            for (index, portion) in portions.enumerated() {
                let endAngle = startAngle + Angle(degrees: portion * 360)
                let path = Path { p in
                    p.move(to: center)
                    p.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
                }
                context.fill(path, with: .color(colors[index]))
                startAngle = endAngle
            }
        }
    }

    private func legendItem(color: Color, label: String, value: String? = nil) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black.opacity(0.6))
            if let v = value {
                Spacer()
                Text(v)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.black.opacity(0.8))
            }
        }
    }

    private func topicCard(icon: String, color: Color, title: String, questions: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.black.opacity(0.8))
                Text(questions)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.black.opacity(0.5))
            }
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.05), lineWidth: 1))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}
