import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var historyService: ReviewHistoryService
    @AppStorage("cull.haptics") private var haptics = true
    @AppStorage("cull.confirmBeforeDelete") private var confirmBeforeDelete = false
    @AppStorage("cull.showMetadata") private var showMetadata = true
    @State private var showResetConfirm = false

    var body: some View {
        ZStack {
            CullTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        settingsSections
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
            "Reset all review history?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                historyService.reset()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Every photo will be available to swipe through again.")
        }
    }

    private var topBar: some View {
        HStack {
            IconPillButton(systemName: "xmark") { dismiss() }
            Spacer()
            Text("Settings")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(CullTheme.text)
            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    @ViewBuilder
    private var settingsSections: some View {
        SectionHeader(label: "REVIEW HISTORY", right: "90·DAY MEMORY")
        SurfaceGroup {
            VStack(spacing: 0) {
                settingsRow(
                    label: "Photos remembered",
                    right: AnyView(
                        Text("\(historyService.keptCount)")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(CullTheme.text)
                            .monospacedDigit()
                    )
                )
                Hairline()
                settingsRow(
                    label: "Memory window",
                    right: AnyView(
                        Text("90 D")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(CullTheme.text2)
                    )
                )
                Hairline()
                settingsRow(
                    label: "Oldest entry",
                    right: AnyView(
                        MonoLabel(text: "—", size: 11, tracking: 0, color: CullTheme.text2)
                    )
                )
            }
        }

        Spacer().frame(height: 22)

        SectionHeader(label: "LIFETIME")
        SurfaceGroup {
            VStack(spacing: 0) {
                settingsRow(
                    label: "Photos culled",
                    right: AnyView(
                        Text(historyService.photosCulled.formatted())
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(CullTheme.text)
                            .monospacedDigit()
                    )
                )
                Hairline()
                settingsRow(
                    label: "Storage freed",
                    right: AnyView(
                        Text(formatBytes(historyService.storageFreedBytes))
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundStyle(CullTheme.amber)
                            .monospacedDigit()
                    )
                )
            }
        }

        Spacer().frame(height: 22)

        SectionHeader(label: "BEHAVIOR")
        SurfaceGroup {
            VStack(spacing: 0) {
                toggleRow(label: "Haptics", binding: $haptics)
                Hairline()
                toggleRow(label: "Confirm before delete", binding: $confirmBeforeDelete)
                Hairline()
                toggleRow(label: "Show metadata strip", binding: $showMetadata)
            }
        }

        Spacer().frame(height: 22)

        VStack(spacing: 0) {
            Button {
                showResetConfirm = true
            } label: {
                HStack {
                    Text("Reset review history")
                        .font(.system(size: 14))
                        .foregroundStyle(CullTheme.del)
                    Spacer()
                    MonoLabel(
                        text: "CLEAR \(historyService.keptCount) ↗",
                        size: 10,
                        tracking: 0,
                        color: CullTheme.del
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .frame(minHeight: 46)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(CullTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(CullTheme.del.opacity(0.3), lineWidth: 1)
        )
    }

    private func settingsRow(label: String, right: AnyView) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(CullTheme.text)
            Spacer()
            right
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(minHeight: 46)
    }

    private func formatBytes(_ bytes: Int) -> String {
        guard bytes > 0 else { return "0 MB" }
        let gb = Double(bytes) / 1_073_741_824
        if gb >= 1 { return String(format: "%.1f GB", gb) }
        let mb = Double(bytes) / 1_048_576
        return String(format: "%.0f MB", mb)
    }

    private func toggleRow(label: String, binding: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(CullTheme.text)
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(CullTheme.keep)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .frame(minHeight: 46)
    }

    private var footer: some View {
        HStack {
            MonoLabel(text: "CULL 1.0.3", size: 10, tracking: 0.18 * 10, color: CullTheme.text4)
            Spacer()
            MonoLabel(text: "BUILD 248", size: 10, tracking: 0.18 * 10, color: CullTheme.text4)
        }
        .padding(.horizontal, 8)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }
}
