import SwiftUI
import CoreML
import Vision
import PhotosUI

import Accelerate

class CoreMLManager {
    static let shared = CoreMLManager()
    
    // Exact model input size
    let targetSize = CGSize(width: 224, height: 224)
    
    /// Standardizes ANY image (Gallery or Bundle) into an identical bit-perfect format.
    /// Uses vImage (Accelerate) for deterministic scaling and forces sRGB color space.
    func standardizeImage(_ image: UIImage) -> UIImage? {
        // 1. Convert UIImage to normalized CGImage (fix rotation, force sRGB)
        guard let cgImage = image.cgImage else { return nil }
        
        // Use a strictly defined sRGB color space to avoid system color management differences
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        
        guard let context = CGContext(data: nil,
                                      width: Int(targetSize.width),
                                      height: Int(targetSize.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: Int(targetSize.width) * 4,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else { return nil }
        
        // 2. Set strict rendering parameters
        context.interpolationQuality = .low // This is Bilinear in Core Graphics
        context.setAllowsAntialiasing(false)
        context.setShouldAntialias(false)
        
        // 3. Draw image centered/fitted into the target rect
        context.draw(cgImage, in: CGRect(origin: .zero, size: targetSize))
        
        guard let outputCGImage = context.makeImage() else { return nil }
        return UIImage(cgImage: outputCGImage)
    }
    
    /// Converts a standardized UIImage to a CVPixelBuffer for ML model input.
    /// This uses kCVPixelFormatType_32ARGB to match standard CoreML requirements.
    func toPixelBuffer(_ image: UIImage) -> CVPixelBuffer? {
        let width = Int(targetSize.width)
        let height = Int(targetSize.height)
        
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, .init(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(buffer, .init(rawValue: 0)) }
        
        guard let pixelData = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        
        // Define color space and bitmap info for ARGB (Big Endian)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        guard let context = CGContext(data: pixelData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: bitmapInfo) else { return nil }
        
        // Final draw to fill the pixel buffer from the source image
        guard let cgImg = image.cgImage else { return nil }
        context.draw(cgImg, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return buffer
    }

    /// DEBUG: Calculates the min/max intensity values to detect blank/black buffers.
    func calculatePixelStats(_ buffer: CVPixelBuffer) -> (min: UInt8, max: UInt8) {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else { return (0, 0) }
        let size = CVPixelBufferGetDataSize(buffer)
        let bufferPointer = UnsafeRawBufferPointer(start: baseAddress, count: size)
        
        var minVal: UInt8 = 255
        var maxVal: UInt8 = 0
        
        for i in 0..<size {
            let val = bufferPointer[i]
            if val < minVal { minVal = val }
            if val > maxVal { maxVal = val }
        }
        
        print("📐 [DEBUG] Buffer: \(CVPixelBufferGetWidth(buffer))x\(CVPixelBufferGetHeight(buffer))")
        print("📐 [DEBUG] Format: \(CVPixelBufferGetPixelFormatType(buffer))")
        print("📐 [DEBUG] Intensity: Min(\(minVal)), Max(\(maxVal))")
        
        return (minVal, maxVal)
    }
}

// MARK: - Modern Image Picker (PHPicker)
struct ModernImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ModernImagePicker
        init(_ parent: ModernImagePicker) { self.parent = parent }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let result = results.first else { return }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                if let uiImage = image as? UIImage {
                    DispatchQueue.main.async {
                        self.parent.selectedImage = uiImage
                    }
                }
            }
        }
    }
}
