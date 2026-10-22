import SwiftUI

/// The end of a session: what it was worth, and two equally easy ways on.
struct DoneView: View {
    let summary: SessionViewModel.Summary
    let onMore: () -> Void
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill((summary.deletionDeclined ? CullTheme.amber : CullTheme.keep).opacity(0.16))
                    Image(systemName: summary.deletionDeclined ? "exclamationmark" : "checkmark")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(summary.deletionDeclined ? CullTheme.amber : CullTheme.keep)
                }
                .frame(width: 84, height: 84)
                .padding(.bottom, 24)

                Text(headline)
                    .font(.system(size: 26, weight: .semibold))
                    .tracking(-0.02 * 26)
                    .foregroundStyle(CullTheme.text)

                detail
                    .font(.system(size: 16))
                    .lineSpacing(4)
                    .foregroundStyle(CullTheme.text2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }
            Spacer()
            PrimaryButton(title: "Clean \(SessionViewModel.batchSize) more", action: onMore)
            QuietButton(title: "Finish for today", action: onFinish)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }

    private var headline: String {
        if summary.reviewed == 0 { return "Nothing decided" }
        if summary.completedBatch { return "That's \(summary.reviewed) done" }
        return "Stopped after \(summary.reviewed)"
    }

    private var detail: Text {
        if summary.deletionDeclined {
            return Text("Nothing was deleted — those photos are still in your library.")
        }
        if summary.reviewed == 0 {
            return Text("You left before deciding anything.")
        }
        if summary.deleted == 0 {
            return Text("You kept all \(summary.reviewed).")
        }
        let photos = summary.deleted == 1 ? "photo" : "photos"
        let freed = Text(StorageEstimate.format(summary.bytesFreed))
            .foregroundColor(CullTheme.amber)
            .fontWeight(.semibold)
        return Text("You deleted \(summary.deleted) \(photos) and freed \(freed).")
    }
}
