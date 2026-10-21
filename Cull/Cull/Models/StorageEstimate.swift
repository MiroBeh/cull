import Foundation

/// The one place a photo's size is guessed at.
///
/// PhotoKit will not tell us what a photo weighs on disk without reading it, so
/// every figure in the app is an estimate — and the only thing worse than an
/// estimate is two of them disagreeing. The review screen, the done screen and
/// the lifetime total all come through here, so they add up.
enum StorageEstimate {
    /// Bytes per pixel of a photo as it is stored: three bytes of RGB at
    /// roughly 10:1 compression.
    private static let bytesPerPixel = 3.0 / 10.0

    /// What a photo we have only counted — never fetched — is assumed to weigh.
    /// The home screen's recoverable figure is this times the unreviewed count.
    static let averagePhotoBytes = 4_000_000

    static func bytes(for photo: Photo) -> Int {
        let pixels = photo.pixelWidth * photo.pixelHeight
        guard pixels > 0 else { return averagePhotoBytes }
        return Int(Double(pixels) * bytesPerPixel)
    }

    static func bytes(for photos: [Photo]) -> Int {
        photos.reduce(0) { $0 + bytes(for: $1) }
    }

    /// For photos we know the number of and nothing else.
    static func bytes(forPhotoCount count: Int) -> Int {
        max(0, count) * averagePhotoBytes
    }

    /// "2.6 GB", "310 MB" — one unit, one decimal at most.
    static func format(_ bytes: Int) -> String {
        let split = split(bytes)
        return "\(split.value) \(split.unit)"
    }

    /// The same figure as a numeral and a unit, for the screens that set the
    /// two in different sizes.
    static func split(_ bytes: Int) -> (value: String, unit: String) {
        let gb = Double(bytes) / 1_073_741_824
        if gb >= 1 { return (String(format: "%.1f", gb), "GB") }
        let mb = Double(bytes) / 1_048_576
        if mb >= 10 { return (String(format: "%.0f", mb), "MB") }
        if mb >= 0.05 { return (String(format: "%.1f", mb), "MB") }
        return ("0", "MB")
    }
}
