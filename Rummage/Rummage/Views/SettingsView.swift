import SwiftUI

/// Short on purpose: the lifetime payoff, what the app remembers, and haptics.
/// There are no settings for things the app no longer does.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var historyService: ReviewHistoryService
    @AppStorage(Haptics.settingsKey) private var haptics = true
    @State private var showResetConfirm = false

    var body: some View {
        ZStack {
            RummageTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        sections
                        footer
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 28)
                    .padding(.bottom, 16)
                }
            }
        }
        .preferredColorScheme(.dark)
        .padding(.top, 54)
        .ignoresSafeArea(edges: .top)
        .confirmationDialog(
            "Reset your review history?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) { historyService.reset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Every photo becomes unreviewed again, and the lifetime totals go back to zero.")
        }
    }

    private var topBar: some View {
        HStack {
            IconPillButton(systemName: "xmark", size: 32) { dismiss() }
            Spacer()
            Text("Settings")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(RummageTheme.text)
            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    @ViewBuilder
    private var sections: some View {
        SectionLabel(text: "Lifetime")
        SurfaceGroup {
            VStack(spacing: 0) {
                row(label: "Photos deleted") {
                    MonoLabel(text: historyService.photosDeleted.formatted(), size: 14, color: RummageTheme.text)
                }
                Hairline()
                row(label: "Storage freed") {
                    MonoLabel(
                        text: StorageEstimate.format(historyService.storageFreedBytes),
                        size: 14,
                        color: RummageTheme.amber
                    )
                }
            }
        }

        Spacer().frame(height: 22)

        SectionLabel(text: "What Rummage remembers")
        SurfaceGroup {
            VStack(spacing: 0) {
                row(label: "Photos you kept") {
                    MonoLabel(text: "\(historyService.keptCount)", size: 14, color: RummageTheme.text)
                }
                Hairline()
                Button {
                    showResetConfirm = true
                } label: {
                    HStack {
                        Text("Reset review history")
                            .font(.system(size: 15))
                            .foregroundStyle(RummageTheme.del)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(RummageTheme.del.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .frame(minHeight: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        Text("A photo you keep is left out of later sessions for 90 days, then comes round again.")
            .font(.system(size: 13))
            .lineSpacing(3)
            .foregroundStyle(RummageTheme.text3)
            .padding(.horizontal, 8)
            .padding(.top, 10)

        Spacer().frame(height: 22)

        SectionLabel(text: "Feel")
        SurfaceGroup {
            HStack {
                Text("Haptics")
                    .font(.system(size: 15))
                    .foregroundStyle(RummageTheme.text)
                Spacer()
                Toggle("", isOn: $haptics)
                    .labelsHidden()
                    .tint(RummageTheme.keep)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(minHeight: 48)
        }
    }

    private func row<Right: View>(label: String, @ViewBuilder right: () -> Right) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(RummageTheme.text)
            Spacer()
            right()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(minHeight: 48)
    }

    private var footer: some View {
        HStack {
            MonoLabel(text: "Rummage \(appVersion)", size: 11, color: RummageTheme.text4)
            Spacer()
            MonoLabel(text: "Build \(buildNumber)", size: 11, color: RummageTheme.text4)
        }
        .padding(.horizontal, 8)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
}
