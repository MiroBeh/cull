import SwiftUI

struct SessionsHomeView: View {
    @Binding var path: [SessionFilter]
    @EnvironmentObject var photoService: PhotoLibraryService
    @EnvironmentObject var historyService: ReviewHistoryService
    @State private var buckets: [MonthBucket] = []
    @State private var isLoading: Bool = true
    @State private var showAlbumPicker: Bool = false
    @State private var showSettings: Bool = false

    var body: some View {
        List {
            Section {
                NavigationLink(value: SessionFilter.all) {
                    Label {
                        Text("Continue swiping").font(.headline)
                    } icon: {
                        Image(systemName: "play.fill").foregroundStyle(.tint)
                    }
                }
            }

            if !buckets.isEmpty {
                Section("By month") {
                    ForEach(buckets) { bucket in
                        NavigationLink(value: SessionFilter.month(year: bucket.year, month: bucket.month)) {
                            HStack {
                                Text(bucket.displayTitle)
                                Spacer()
                                Text("\(bucket.unreviewedCount) unreviewed")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    showAlbumPicker = true
                } label: {
                    Label {
                        Text("By album").foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "rectangle.stack").foregroundStyle(.tint)
                    }
                }
            }
        }
        .navigationTitle("Cull")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .task {
            await loadBuckets()
        }
        .onAppear {
            Task { await loadBuckets() }
        }
        .refreshable {
            await loadBuckets()
        }
        .sheet(isPresented: $showAlbumPicker) {
            AlbumPickerView { filter in
                showAlbumPicker = false
                path.append(filter)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
        .overlay {
            if isLoading && buckets.isEmpty {
                ProgressView("Loading library…")
            }
        }
    }

    private func loadBuckets() async {
        isLoading = true
        buckets = await photoService.fetchMonthBuckets(history: historyService)
        isLoading = false
    }
}

struct SettingsSheet: View {
    @EnvironmentObject var historyService: ReviewHistoryService
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section("Review History") {
                    HStack {
                        Text("Photos remembered")
                        Spacer()
                        Text("\(historyService.keptCount)")
                            .foregroundStyle(.secondary)
                    }
                    Text("Cull remembers photos you've kept for 90 days so you don't see them again.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Reset review history", role: .destructive) {
                        showResetConfirm = true
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Reset all review history?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    historyService.reset()
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Every photo will be available to swipe through again.")
            }
        }
    }
}
