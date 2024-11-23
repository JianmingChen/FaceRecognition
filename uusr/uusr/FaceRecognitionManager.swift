import Vision
import UIKit

class FaceRecognitionManager {
    static let shared = FaceRecognitionManager()
    
    private init() {}
    
    // Store face encodings for registered users
    private var faceEncodings: [String: [CGPoint]] = [:]
    
    func encodeFace(from image: UIImage, for userId: String, completion: @escaping (Bool, [CGPoint]?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(false, nil)
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let faceDetectionRequest = VNDetectFaceLandmarksRequest { request, error in
            guard let observations = request.results as? [VNFaceObservation],
                  let firstFace = observations.first,
                  let landmarks = firstFace.landmarks else {
                completion(false, nil)
                return
            }
            
            if let allPoints = landmarks.allPoints {
                let points = self.normalizedPoints(from: allPoints, boundingBox: firstFace.boundingBox)
                self.faceEncodings[userId] = points
                completion(true, points)
            } else {
                completion(false, nil)
            }
        }
        
        try? requestHandler.perform([faceDetectionRequest])
    }
    
    /// Matches a captured face with stored encodings.
    /// - Parameters:
    ///   - image: The captured face image.
    ///   - completion: Callback with the user ID of the best match, or `nil` if no match is found.
    func matchFace(from image: UIImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let faceDetectionRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let observations = request.results as? [VNFaceObservation],
                  let firstFace = observations.first,
                  let landmarks = firstFace.landmarks,
                  let allPoints = landmarks.allPoints else {
                completion(nil)
                return
            }
            
            let capturedPoints = self?.normalizedPoints(from: allPoints, boundingBox: firstFace.boundingBox) ?? []
            
            // Find the best match
            var bestMatch: (userId: String, similarity: Float)?
            
            for (userId, storedPoints) in self?.faceEncodings ?? [:] {
                let similarity = self?.calculateSimilarity(points1: capturedPoints, points2: storedPoints) ?? 0
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
    
    private func normalizedPoints(from points: VNFaceLandmarkRegion2D, boundingBox: CGRect) -> [CGPoint] {
        return points.normalizedPoints.map { point in
            CGPoint(
                x: boundingBox.origin.x + point.x * boundingBox.size.width,
                y: boundingBox.origin.y + point.y * boundingBox.size.height
            )
        }
    }
    
    func calculateSimilarity(points1: [CGPoint], points2: [CGPoint]) -> Float {
        guard points1.count == points2.count else { return 0 }
        
        var totalDistance: Float = 0.0
        for i in 0..<points1.count {
            let dx = Float(points1[i].x - points2[i].x)
            let dy = Float(points1[i].y - points2[i].y)
            totalDistance += sqrt(dx * dx + dy * dy)
        }
        
        let averageDistance = totalDistance / Float(points1.count)
        return max(0, 1 - averageDistance) // Higher score for closer matches
    }
}
