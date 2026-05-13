import SwiftUI
import Photos

struct AlbumPickerView: View {
    let onPick: (SessionFilter) -> Void
    @EnvironmentObject var photoService: PhotoLibraryService
    @Environment(\.dismiss) private var dismiss
    @State private var albums: [PHAssetCollection] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if albums.isEmpty {
                    Text("No albums found")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(albums, id: \.localIdentifier) { album in
                        Button {
                            onPick(.album(
                                localId: album.localIdentifier,
                                title: album.localizedTitle ?? "Untitled"
                            ))
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.stack")
                                    .foregroundStyle(.tint)
                                Text(album.localizedTitle ?? "Untitled")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Pick Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                albums = await photoService.fetchAlbums()
                isLoading = false
            }
        }
    }
}
