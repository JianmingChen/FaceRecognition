import Vision
import UIKit

class FaceRecognitionManager {
    static let shared = FaceRecognitionManager()
    
    private init() {}
    
    // Store face encodings for registered users
    private var faceEncodings: [String: VNFaceObservation] = [:]
    
    func encodeFace(from image: UIImage, for userId: String, completion: @escaping (Bool) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(false)
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let faceDetectionRequest = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let observations = request.results as? [VNFaceObservation],
                  let firstFace = observations.first else {
                completion(false)
                return
            }
            
            self?.faceEncodings[userId] = firstFace
            completion(true)
        }
        
        try? requestHandler.perform([faceDetectionRequest])
    }
    
    func matchFace(from image: UIImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let faceDetectionRequest = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let observations = request.results as? [VNFaceObservation],
                  let firstFace = observations.first else {
                completion(nil)
                return
            }
            
            // Find the best match
            var bestMatch: (userId: String, similarity: Float)?
            
            for (userId, storedFace) in self?.faceEncodings ?? [:] {
                let similarity = self?.calculateSimilarity(face1: firstFace, face2: storedFace) ?? 0
                if similarity > 0.8 { // Threshold for matching
                    if bestMatch == nil || similarity > bestMatch!.similarity {
                        bestMatch = (userId, similarity)
                    }
                }
            }
            
            completion(bestMatch?.userId)
        }
        
        try? requestHandler.perform([faceDetectionRequest])
    }
    
    private func calculateSimilarity(face1: VNFaceObservation, face2: VNFaceObservation) -> Float {
        // Simple similarity calculation based on face landmarks
        // In a production environment, you'd want a more sophisticated comparison
        let boundingBoxSimilarity = 1 - Float(abs(face1.boundingBox.width - face2.boundingBox.width))
        return boundingBoxSimilarity
    }
} 