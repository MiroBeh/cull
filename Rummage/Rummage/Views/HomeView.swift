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
            RummageTheme.bg.ignoresSafeArea()

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
            MonoLabel(text: "Rummage", size: 14, tracking: 0.22 * 14, color: RummageTheme.text, uppercase: true)
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
            ProgressView().tint(RummageTheme.text2)
            Spacer()
        }
    }

    private func ready(unreviewed: Int) -> some View {
        let recoverable = StorageEstimate.valueAndUnit(StorageEstimate.bytes(forPhotoCount: unreviewed))

        return VStack(alignment: .leading, spacing: 0) {
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(recoverable.value)
                    .rummageMono(size: 68, tracking: -0.04 * 68)
                    .foregroundStyle(RummageTheme.amber)
                    .monospacedDigit()
                Text(recoverable.unit)
                    .rummageMono(size: 24)
                    .foregroundStyle(RummageTheme.amber)
            }
            Text("can be freed from photos you haven't looked at yet.")
                .font(.system(size: 17))
                .lineSpacing(5)
                .foregroundStyle(RummageTheme.text2)
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
                .foregroundStyle(RummageTheme.text)
            Text("Every photo in your library has been through Rummage. Come back when you have taken some more.")
                .font(.system(size: 17))
                .lineSpacing(5)
                .foregroundStyle(RummageTheme.text2)
                .frame(maxWidth: 300, alignment: .leading)
                .padding(.top, 14)
            Spacer()
            lifetimeLine
        }
    }

    private var noAccess: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text("Rummage needs your photos.")
                .font(.system(size: 28, weight: .semibold))
                .tracking(-0.02 * 28)
                .foregroundStyle(RummageTheme.text)
            Text("Without access to the library there is nothing to clean. You can grant it in Settings — nothing leaves your device unless you share it.")
                .font(.system(size: 17))
                .lineSpacing(5)
                .foregroundStyle(RummageTheme.text2)
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
            Text("You've freed \(StorageEstimate.format(historyService.storageFreedBytes)) with Rummage so far")
                .font(.system(size: 13))
                .foregroundStyle(RummageTheme.text3)
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
        unreviewed = await photoService.unreviewedCount(excluding: historyService.keptIDs)
    }
}
