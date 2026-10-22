import SwiftUI
import UIKit

/// A storage number and one button. Nothing to choose, because choosing between
/// "March 2026" and "September 2025" is not a decision anyone has an opinion
/// about.
struct HomeView: View {
    @EnvironmentObject var photoService: PhotoLibraryService
    @EnvironmentObject var historyService: ReviewHistoryService
    @Environment(\.scenePhase) private var scenePhase

    @State private var unreviewed: Int?
    @State private var isReviewing = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            CullTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                content
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .preferredColorScheme(.dark)
        .padding(.top, 54)
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .task { await refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refresh() } }
        }
        .onChange(of: isReviewing) { _, reviewing in
            // Coming back from a session: the count and the lifetime figure
            // have both moved.
            if !reviewing { Task { await refresh() } }
        }
        .navigationDestination(isPresented: $isReviewing) {
            ReviewView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(historyService)
        }
    }

    private var topBar: some View {
        HStack {
            MonoLabel(text: "Cull", size: 14, tracking: 0.22 * 14, color: CullTheme.text, uppercase: true)
            Spacer()
            IconPillButton(systemName: "gearshape", size: 40) { showSettings = true }
        }
        .padding(.top, 10)
    }

    @ViewBuilder
    private var content: some View {
        if !photoService.hasAccess {
            noAccess
        } else if let unreviewed {
            if unreviewed == 0 {
                allDone
            } else {
                ready(unreviewed: unreviewed)
            }
        } else {
            Spacer()
            ProgressView().tint(CullTheme.text2)
            Spacer()
        }
    }

    private func ready(unreviewed: Int) -> some View {
        let recoverable = StorageEstimate.valueAndUnit(StorageEstimate.bytes(forPhotoCount: unreviewed))

        return VStack(alignment: .leading, spacing: 0) {
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(recoverable.value)
                    .cullMono(size: 68, tracking: -0.04 * 68)
                    .foregroundStyle(CullTheme.amber)
                    .monospacedDigit()
                Text(recoverable.unit)
                    .cullMono(size: 24)
                    .foregroundStyle(CullTheme.amber)
            }
            Text("can be freed from photos you haven't looked at yet.")
                .font(.system(size: 17))
                .lineSpacing(5)
                .foregroundStyle(CullTheme.text2)
                .frame(maxWidth: 260, alignment: .leading)
                .padding(.top, 16)
            Spacer()
            PrimaryButton(title: "Start cleaning") { isReviewing = true }
            HintLine(text: "\(SessionViewModel.batchSize) photos at a time · about two minutes")
                .padding(.top, 14)
            lifetimeLine
        }
    }

    private var allDone: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text("You're all caught up.")
                .font(.system(size: 28, weight: .semibold))
                .tracking(-0.02 * 28)
                .foregroundStyle(CullTheme.text)
            Text("Every photo in your library has been through Cull. Come back when you have taken some more.")
                .font(.system(size: 17))
                .lineSpacing(5)
                .foregroundStyle(CullTheme.text2)
                .frame(maxWidth: 300, alignment: .leading)
                .padding(.top, 14)
            Spacer()
            lifetimeLine
        }
    }

    private var noAccess: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text("Cull needs your photos.")
                .font(.system(size: 28, weight: .semibold))
                .tracking(-0.02 * 28)
                .foregroundStyle(CullTheme.text)
            Text("Without access to the library there is nothing to clean. You can grant it in Settings — nothing leaves your device unless you share it.")
                .font(.system(size: 17))
                .lineSpacing(5)
                .foregroundStyle(CullTheme.text2)
                .frame(maxWidth: 300, alignment: .leading)
                .padding(.top, 14)
            Spacer()
            PrimaryButton(title: "Open Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
        }
    }

    @ViewBuilder
    private var lifetimeLine: some View {
        if historyService.storageFreedBytes > 0 {
            Text("You've freed \(StorageEstimate.format(historyService.storageFreedBytes)) with Cull so far")
                .font(.system(size: 13))
                .foregroundStyle(CullTheme.text3)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
        }
    }

    private func refresh() async {
        photoService.refreshAuthorizationStatus()
        guard photoService.hasAccess else {
            unreviewed = 0
            return
        }
        historyService.pruneExpired()
        unreviewed = await photoService.unreviewedCount(history: historyService)
    }
}
