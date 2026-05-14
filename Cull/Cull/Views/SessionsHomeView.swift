import SwiftUI

struct SessionsHomeView: View {
    @Binding var path: [SessionFilter]
    @EnvironmentObject var photoService: PhotoLibraryService
    @EnvironmentObject var historyService: ReviewHistoryService
    @State private var buckets: [MonthBucket] = []
    @State private var isLoading: Bool = true
    @State private var showSettings: Bool = false
    @State private var showAlbumPicker: Bool = false

    private var unreviewedTotal: Int {
        buckets.reduce(0) { $0 + $1.unreviewedCount }
    }

    private var estimatedGB: Double {
        Double(unreviewedTotal) * 4_000_000 / 1_073_741_824
    }

    private var continueBucket: MonthBucket? {
        buckets.first { $0.unreviewedCount > 0 }
    }

    private static let monthFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f
    }()

    private static let yearFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy"
        return f
    }()

    private func monthName(_ bucket: MonthBucket) -> String {
        var c = DateComponents()
        c.year = bucket.year
        c.month = bucket.month
        guard let d = Calendar.current.date(from: c) else { return "" }
        return Self.monthFmt.string(from: d)
    }

    private func yearString(_ bucket: MonthBucket) -> String {
        var c = DateComponents()
        c.year = bucket.year
        c.month = bucket.month
        guard let d = Calendar.current.date(from: c) else { return "" }
        return Self.yearFmt.string(from: d)
    }

    var body: some View {
        ZStack {
            CullTheme.bg.ignoresSafeArea()

            if isLoading && buckets.isEmpty {
                ProgressView()
                    .tint(CullTheme.text2)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        topBar
                        heroSection
                        if let bucket = continueBucket {
                            continueCTA(bucket: bucket)
                        }
                        byMonthHeader
                        monthList
                    }
                }
                .refreshable { await loadBuckets() }
            }
        }
        .preferredColorScheme(.dark)
        .padding(.top, 54)
        .ignoresSafeArea(edges: .top)
        .task { await loadBuckets() }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(historyService)
        }
        .sheet(isPresented: $showAlbumPicker) {
            AlbumPickerView { filter in
                showAlbumPicker = false
                path.append(filter)
            }
            .environmentObject(photoService)
        }
    }

    private var topBar: some View {
        HStack {
            MonoLabel(text: "CULL", size: 11, tracking: 0.22 * 11, color: CullTheme.text)
            Spacer()
            IconPillButton(systemName: "gearshape") { showSettings = true }
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 0)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            MonoLabel(text: "RECOVERABLE", size: 10, tracking: 0.22 * 10, color: CullTheme.text3)
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(String(format: "%.1f", estimatedGB))
                    .cullSans(size: 64, weight: .medium, tracking: -0.04 * 64)
                    .foregroundStyle(CullTheme.amber)
                    .monospacedDigit()
                Text("GB")
                    .font(.system(size: 22, weight: .medium, design: .monospaced))
                    .foregroundStyle(CullTheme.amber)
            }
            .padding(.top, 10)
            HStack(spacing: 4) {
                Text("across")
                    .font(.system(size: 13))
                    .foregroundStyle(CullTheme.text2)
                Text("\(unreviewedTotal)")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(CullTheme.text)
                    .monospacedDigit()
                Text("unreviewed photos")
                    .font(.system(size: 13))
                    .foregroundStyle(CullTheme.text2)
            }
            .padding(.top, 10)
        }
        .padding(.horizontal, 24)
        .padding(.top, 36)
        .padding(.bottom, 20)
    }

    private func continueCTA(bucket: MonthBucket) -> some View {
        let reviewed = bucket.totalCount - bucket.unreviewedCount
        let progress = bucket.totalCount > 0
            ? Double(reviewed) / Double(bucket.totalCount)
            : 0.0

        return SurfaceGroup {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(CullTheme.amberDim)
                        .frame(width: 36, height: 36)
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(CullTheme.amber)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Continue \(monthName(bucket))")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(CullTheme.text)
                    MonoLabel(
                        text: "\(reviewed) / \(bucket.totalCount) · — MB FREED",
                        size: 10,
                        tracking: 0.14 * 10,
                        color: CullTheme.text3
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ThinProgressBar(value: progress, color: CullTheme.amber, height: 3)
                    .frame(width: 80)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 22)
        .contentShape(Rectangle())
        .onTapGesture {
            path.append(.month(year: bucket.year, month: bucket.month))
        }
    }

    private var byMonthHeader: some View {
        HStack {
            MonoLabel(text: "BY MONTH", size: 10, tracking: 0.22 * 10, color: CullTheme.text3)
            Spacer()
            MonoLabel(text: "UNREVIEWED · FREED", size: 10, tracking: 0.22 * 10, color: CullTheme.text4)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
    }

    private var monthList: some View {
        SurfaceGroup {
            VStack(spacing: 0) {
                ForEach(Array(buckets.enumerated()), id: \.element.id) { index, bucket in
                    bucketRow(bucket: bucket)
                    if index < buckets.count - 1 {
                        Hairline()
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private func bucketRow(bucket: MonthBucket) -> some View {
        let isComplete = bucket.unreviewedCount == 0
        let reviewed = bucket.totalCount - bucket.unreviewedCount
        let progress = bucket.totalCount > 0
            ? Double(reviewed) / Double(bucket.totalCount)
            : 0.0

        return Button {
            path.append(.month(year: bucket.year, month: bucket.month))
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
                        Text(monthName(bucket))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(isComplete ? CullTheme.text3 : CullTheme.text)
                        Text(yearString(bucket))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(CullTheme.text4)
                        if isComplete {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(CullTheme.keep)
                        }
                    }
                    ThinProgressBar(
                        value: progress,
                        color: isComplete ? CullTheme.keep : CullTheme.text2,
                        height: 2
                    )
                    .frame(width: 84)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(bucket.unreviewedCount)")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(isComplete ? CullTheme.text3 : CullTheme.text)
                        .monospacedDigit()
                    if isComplete {
                        MonoLabel(text: "— GB", size: 10, tracking: 0.08 * 10, color: CullTheme.amber)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(CullTheme.text4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func loadBuckets() async {
        isLoading = true
        buckets = await photoService.fetchMonthBuckets(history: historyService)
        isLoading = false
    }
}
