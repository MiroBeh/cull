import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var viewModel: CullViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            Text("Session Complete")
                .font(.largeTitle.bold())
            statsCard
            Spacer()
            Button("Done") {
                viewModel.reset()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom, 32)
        }
        .padding(.horizontal)
    }

    private var statsCard: some View {
        VStack(spacing: 16) {
            statRow(symbol: "checkmark.circle", color: .green,
                    label: "Kept", value: "\(viewModel.toKeep.count) photos")
            Divider()
            statRow(symbol: "trash.circle", color: .red,
                    label: "Deleted", value: "\(viewModel.toDelete.count) photos")
            Divider()
            statRow(symbol: "internaldrive", color: .blue,
                    label: "Storage Freed", value: viewModel.storageSavedEstimate())
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func statRow(symbol: String, color: Color, label: String, value: String) -> some View {
        HStack {
            Image(systemName: symbol).foregroundStyle(color).frame(width: 28)
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
    }
}
