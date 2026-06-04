import SwiftUI

struct ProfileView: View {
    @AppStorage("nextstep_userName") private var userName: String = ""
    @State private var isEditingName = false
    @State private var editedName: String = ""

    private let persistence = PersistenceService.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Profile header
                profileHeader
                    .padding(.top, 32)
                    .padding(.bottom, 28)

                // Stats section
                statsSection
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)

                // Settings section
                settingsSection
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)

                // About section
                aboutSection
                    .padding(.horizontal, 28)
                    .padding(.bottom, 32)
            }
        }
        .background(Color.welcomeBg.ignoresSafeArea())
        .alert("Edit Name", isPresented: $isEditingName) {
            TextField("Your name", text: $editedName)
            Button("Save") {
                userName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Enter your display name")
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.ringYellow, Color.ringGreen, Color.ringBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                // Inner white circle with initial
                Circle()
                    .fill(Color.paperWhite)
                    .frame(width: 90, height: 90)

                Text(userInitial)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.inkColor)
            }

            // Name
            Text(userName.isEmpty ? "Buddy" : userName)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkColor)

            // Edit name button
            Button(action: {
                editedName = userName
                isEditingName = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Edit Name")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Color.accentBlue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.accentBlue.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Progress")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkColor)
                .padding(.bottom, 4)

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                statCard(
                    icon: "flame.fill",
                    iconColor: Color.streakOrange,
                    title: "\(persistence.currentStreak)",
                    subtitle: "Day Streak"
                )

                statCard(
                    icon: "clock.fill",
                    iconColor: Color.timeGreen,
                    title: persistence.formattedStudyTime,
                    subtitle: "Study Time"
                )

                statCard(
                    icon: "star.fill",
                    iconColor: Color.ringYellow,
                    title: "\(persistence.aggregateIndependenceScore)",
                    subtitle: "Independence"
                )

                statCard(
                    icon: "lightbulb.fill",
                    iconColor: Color.accentAmber,
                    title: "\(persistence.totalHintsUsed)",
                    subtitle: "Hints Used"
                )
            }

            // Sessions count
            let sessionCount = persistence.loadAllSessions().count
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.accentBlue)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(sessionCount) Problem\(sessionCount == 1 ? "" : "s") Solved")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkColor)
                    Text("Total problems attempted")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.inkColor.opacity(0.5))
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.paperWhite)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.paperBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkColor)
                .padding(.bottom, 4)

            settingsRow(icon: "bell.fill", title: "Notifications", subtitle: "Reminders to study")
            settingsRow(icon: "moon.fill", title: "Appearance", subtitle: "Light & dark mode")
            settingsRow(icon: "lock.fill", title: "Privacy", subtitle: "Data & permissions")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkColor)
                .padding(.bottom, 4)

            // App version
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.ringYellow.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.ringYellow)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("NextStep")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkColor)
                    Text("Version 1.0 · Made with ❤️")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.inkColor.opacity(0.5))
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.paperWhite)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.paperBorder, lineWidth: 1)
            )

            // Reset data button
            Button(action: {
                persistence.clearAll()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14))
                    Text("Reset All Data")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                }
                .foregroundStyle(Color.solveBtnBg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.solveBtnBg.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.solveBtnBg.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    private func statCard(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(iconColor)

            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.inkColor)

            Text(subtitle)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkColor.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.paperWhite)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.paperBorder, lineWidth: 1)
        )
    }

    private func settingsRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentBlue.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.accentBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkColor)
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.inkColor.opacity(0.5))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.inkColor.opacity(0.3))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.paperWhite)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.paperBorder, lineWidth: 1)
        )
    }

    private var userInitial: String {
        let name = userName.isEmpty ? "B" : userName
        return String(name.prefix(1)).uppercased()
    }
}
