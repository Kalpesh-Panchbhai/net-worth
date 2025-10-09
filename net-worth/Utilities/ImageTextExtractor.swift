import Foundation
import Vision
import UIKit

/// Utility to extract text from images using Apple's Vision framework
struct ImageTextExtractor {
    
    /// Extract all text from an image
    /// - Parameter image: UIImage to extract text from
    /// - Returns: Array of recognized text strings
    static func extractText(from image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw ExtractionError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                continuation.resume(returning: recognizedStrings)
            }
            
            // Configure for accurate recognition
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    enum ExtractionError: LocalizedError {
        case invalidImage
        case noTextFound
        
        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Invalid image format"
            case .noTextFound:
                return "No text found in image"
            }
        }
    }
}
