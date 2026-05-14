import SwiftUI
import Photos

struct SummaryView: View {
    @EnvironmentObject var viewModel: CullViewModel
    @Environment(\.dismiss) private var dismiss

    private static let sessionFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "'SESSION · 'MM'·'yy"
        return f
    }()

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private var sessionLabel: String {
        Self.sessionFmt.string(from: Date()).uppercased()
    }

    private var timeLabel: String {
        Self.timeFmt.string(from: Date())
    }

    private var totalCleared: Int {
        viewModel.toKeep.count + viewModel.toDelete.count
    }

    private static let heroMonthFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f
    }()

    private var heroMonth: String {
        Self.heroMonthFmt.string(from: Date())
    }

    private var gbFreed: Double {
        Double(viewModel.toDelete.count) * 4.0 / 1024.0
    }

    private var largestMB: String {
        let sizes = viewModel.toDelete.map {
            $0.asset.pixelWidth * $0.asset.pixelHeight
        }
        guard let maxPixels = sizes.max(), maxPixels > 0 else { return "—" }
        let mb = Double(maxPixels) * 3 / 10 / 1_048_576
        return String(format: "%.0f MB", mb)
    }

    private var avgMB: String {
        let count = viewModel.toDelete.count
        guard count > 0 else { return "—" }
        let totalMB = viewModel.toDelete.reduce(0.0) { acc, p in
            acc + Double(p.asset.pixelWidth * p.asset.pixelHeight) * 3 / 10 / 1_048_576
        }
        return String(format: "%.1f", totalMB / Double(count))
    }

    private var deletePct: Int {
        let total = totalCleared
        guard total > 0 else { return 0 }
        return Int(Double(viewModel.toDelete.count) / Double(total) * 100)
    }

    private var keepPct: Int { 100 - deletePct }

    var body: some View {
        ZStack {
            CullTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                    heroSection
                    freedSection
                    statsSection
                    decisionsSection
                    Spacer().frame(height: 24)
                    ctaSection
                    Spacer().frame(height: 28)
                }
            }
        }
        .preferredColorScheme(.dark)
        .padding(.top, 54)
        .ignoresSafeArea(edges: .top)
    }

    private var topBar: some View {
        HStack {
            MonoLabel(text: sessionLabel, size: 11, tracking: 0.22 * 11, color: CullTheme.text3)
            Spacer()
            MonoLabel(text: timeLabel, size: 11, tracking: 0.22 * 11, color: CullTheme.text3)
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(heroMonth) done.")
                .cullSans(size: 40, weight: .medium, tracking: -0.02 * 40)
                .foregroundStyle(CullTheme.text)
            Text("You cleared \(totalCleared) photos.")
                .font(.system(size: 16))
                .foregroundStyle(CullTheme.text3)
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
    }

    private var freedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            MonoLabel(text: "STORAGE FREED", size: 10, tracking: 0.22 * 10, color: CullTheme.text3)
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(String(format: "%.2f", gbFreed))
                    .font(.system(size: 80, weight: .medium, design: .monospaced))
                    .foregroundStyle(CullTheme.amber)
                    .monospacedDigit()
                Text("GB")
                    .font(.system(size: 28, weight: .medium, design: .monospaced))
                    .foregroundStyle(CullTheme.amber)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 30)
    }

    private var statsSection: some View {
        SurfaceGroup {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 0) {
                statCell(label: "KEPT", value: "\(viewModel.toKeep.count)", color: CullTheme.keep,
                         borderLeft: false, borderTop: false)
                statCell(label: "DELETED", value: "\(viewModel.toDelete.count)", color: CullTheme.del,
                         borderLeft: true, borderTop: false)
                statCell(label: "LARGEST", value: largestMB, color: CullTheme.text,
                         borderLeft: false, borderTop: true)
                statCell(label: "AVG · MB", value: avgMB, color: CullTheme.text,
                         borderLeft: true, borderTop: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 32)
    }

    private func statCell(
        label: String, value: String, color: Color,
        borderLeft: Bool, borderTop: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            MonoLabel(text: label, size: 10, tracking: 0.18 * 10, color: CullTheme.text3)
            Text(value)
                .font(.system(size: 26, weight: .medium, design: .monospaced))
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .overlay(alignment: .leading) {
            if borderLeft { Rectangle().fill(CullTheme.lineSolid).frame(width: 1) }
        }
        .overlay(alignment: .top) {
            if borderTop { Rectangle().fill(CullTheme.lineSolid).frame(height: 1) }
        }
    }

    private var decisionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            MonoLabel(text: "DECISIONS", size: 10, tracking: 0.22 * 10, color: CullTheme.text3)
            GeometryReader { geo in
                HStack(spacing: 2) {
                    let total = viewModel.toDelete.count + viewModel.toKeep.count
                    let delFraction = total > 0
                        ? CGFloat(viewModel.toDelete.count) / CGFloat(total)
                        : 0.5
                    let delWidth = (geo.size.width - 2) * delFraction
                    let keepWidth = geo.size.width - 2 - delWidth

                    RoundedRectangle(cornerRadius: 999)
                        .fill(CullTheme.del)
                        .frame(width: max(delWidth, 4), height: 8)
                    RoundedRectangle(cornerRadius: 999)
                        .fill(CullTheme.keep)
                        .frame(width: max(keepWidth, 4), height: 8)
                }
            }
            .frame(height: 8)
            HStack {
                MonoLabel(
                    text: "\(viewModel.toDelete.count) DELETED · \(deletePct)%",
                    size: 10, tracking: 0.12 * 10, color: CullTheme.del
                )
                Spacer()
                MonoLabel(
                    text: "\(viewModel.toKeep.count) KEPT · \(keepPct)%",
                    size: 10, tracking: 0.12 * 10, color: CullTheme.keep
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    private var ctaSection: some View {
        VStack(spacing: 8) {
            Button {
                viewModel.reset()
                dismiss()
            } label: {
                HStack {
                    Text("Done")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(CullTheme.bg)
                    Spacer()
                    MonoLabel(text: "→ HOME", size: 10, tracking: 0.14 * 10, color: CullTheme.bg)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(CullTheme.text)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Button {
                viewModel.reset()
                dismiss()
            } label: {
                Text("Back to library")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(CullTheme.text2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(CullTheme.lineSolid, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
    }
}
