import SwiftUI
import Photos

struct AlbumPickerView: View {
    let onPick: (SessionFilter) -> Void
    @EnvironmentObject var photoService: PhotoLibraryService
    @Environment(\.dismiss) private var dismiss
    @State private var albums: [PHAssetCollection] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            CullTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(CullTheme.text2)
                    Spacer()
                } else if albums.isEmpty {
                    Spacer()
                    Text("No albums found")
                        .font(.system(size: 15))
                        .foregroundStyle(CullTheme.text3)
                    Spacer()
                } else {
                    albumList
                }
            }
        }
        .preferredColorScheme(.dark)
        .padding(.top, 54)
        .ignoresSafeArea(edges: .top)
        .task {
            albums = await photoService.fetchAlbums()
            isLoading = false
        }
    }

    private var topBar: some View {
        HStack {
            IconPillButton(systemName: "xmark") { dismiss() }
            Spacer()
            Text("Pick Album")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(CullTheme.text)
            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
    }

    private var albumList: some View {
        ScrollView {
            SurfaceGroup {
                VStack(spacing: 0) {
                    ForEach(Array(albums.enumerated()), id: \.element.localIdentifier) { index, album in
                        albumRow(album: album)
                        if index < albums.count - 1 {
                            Hairline()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func albumRow(album: PHAssetCollection) -> some View {
        let title = album.localizedTitle ?? "Untitled"
        let count = album.estimatedAssetCount

        return Button {
            onPick(.album(localId: album.localIdentifier, title: title))
            dismiss()
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundStyle(CullTheme.text)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if count != NSNotFound {
                    Text("\(count)")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(CullTheme.text2)
                        .monospacedDigit()
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(CullTheme.text4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .frame(minHeight: 46)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
