import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import Cull

/// A shared photo is the photo, without where it was taken.
struct ShareTests {

    /// A 4×4 image of the given type carrying a GPS position and a camera make.
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
            kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFMake: "Cull"],
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

    @Test func somethingThatIsNotAnImageIsNotShared() {
        #expect(SharablePhoto.removingLocation(from: Data("not a photo".utf8)) == nil)
    }
}
