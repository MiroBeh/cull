import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import Rummage

/// A shared photo is the photo, without where it was taken.
struct ShareTests {

    /// A 4×4 image of the given type carrying a GPS position, the place as
    /// words, and a camera make.
    private func photoData(type: UTType) throws -> Data {
        let context = try #require(CGContext(
            data: nil, width: 4, height: 4, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        context.setFillColor(red: 0.9, green: 0.75, blue: 0.43, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        let image = try #require(context.makeImage())

        let data = NSMutableData()
        let destination = try #require(
            CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil)
        )
        let properties: [CFString: Any] = [
            kCGImagePropertyGPSDictionary: [
                kCGImagePropertyGPSLatitude: 48.2082,
                kCGImagePropertyGPSLatitudeRef: "N",
                kCGImagePropertyGPSLongitude: 16.3738,
                kCGImagePropertyGPSLongitudeRef: "E",
            ],
            kCGImagePropertyIPTCDictionary: [
                kCGImagePropertyIPTCCity: "Wien",
                kCGImagePropertyIPTCSubLocation: "Stephansplatz 3",
                kCGImagePropertyIPTCCountryPrimaryLocationName: "Austria",
            ],
            kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFMake: "Rummage"],
            kCGImagePropertyOrientation: 6,
        ]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        return data as Data
    }

    private func properties(of data: Data) throws -> [CFString: Any] {
        let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        return try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
    }

    @Test(arguments: [UTType.jpeg, .heic, .png])
    func aSharedPhotoCarriesNoLocation(type: UTType) throws {
        let original = try photoData(type: type)
        try #require(try properties(of: original)[kCGImagePropertyGPSDictionary] != nil)

        let shared = try #require(SharablePhoto.removingLocation(from: original))
        let kept = try properties(of: shared)

        #expect(kept[kCGImagePropertyGPSDictionary] == nil)
        #expect(kept[kCGImagePropertyOrientation] as? Int == 6)
    }

    /// Coordinates are not the only way a photo says where it was taken: a
    /// city and a street in the IPTC or XMP fields say it just as well.
    @Test(arguments: [UTType.jpeg, .heic])
    func aSharedPhotoCarriesNoPlaceName(type: UTType) throws {
        let original = try photoData(type: type)
        let place = try #require(properties(of: original)[kCGImagePropertyIPTCDictionary] as? [CFString: Any])
        try #require(place[kCGImagePropertyIPTCSubLocation] as? String == "Stephansplatz 3")

        let shared = try #require(SharablePhoto.removingLocation(from: original))
        let kept = try properties(of: shared)[kCGImagePropertyIPTCDictionary] as? [CFString: Any] ?? [:]

        #expect(kept[kCGImagePropertyIPTCCity] == nil)
        #expect(kept[kCGImagePropertyIPTCSubLocation] == nil)
        #expect(kept[kCGImagePropertyIPTCCountryPrimaryLocationName] == nil)

        let metadata = try #require(
            CGImageSourceCreateWithData(shared as CFData, nil)
                .flatMap { CGImageSourceCopyMetadataAtIndex($0, 0, nil) }
        )
        #expect(CGImageMetadataCopyTagWithPath(metadata, nil, "photoshop:City" as CFString) == nil)
        #expect(CGImageMetadataCopyTagWithPath(metadata, nil, "Iptc4xmpCore:Location" as CFString) == nil)
    }

    @Test func somethingThatIsNotAnImageIsNotShared() {
        #expect(SharablePhoto.removingLocation(from: Data("not a photo".utf8)) == nil)
    }
}
