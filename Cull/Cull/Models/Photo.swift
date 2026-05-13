import Photos

struct Photo: Identifiable, Hashable {
    let asset: PHAsset

    var id: String { asset.localIdentifier }
    var creationDate: Date? { asset.creationDate }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Photo, rhs: Photo) -> Bool {
        lhs.id == rhs.id
    }
}

enum SwipeDecision {
    case keep, delete
}
