import Vision
import UIKit

class FaceRecognitionManager {
    static let shared = FaceRecognitionManager()

    private var faceEncodings: [String: [CGPoint]] = [:]

    private init() {}

    /// Encodes a face from a given image and stores it with a user ID.
    func encodeFace(from image: UIImage, for userId: String, completion: @escaping (Bool, [CGPoint]?) -> Void) {
        guard let cgImage = image.cgImage else {
            print("Image conversion to CGImage failed.")
            completion(false, nil)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let faceDetectionRequest = VNDetectFaceLandmarksRequest { request, error in
                guard error == nil,
                      let observations = request.results as? [VNFaceObservation],
                      let firstFace = observations.first,
                      let landmarks = firstFace.landmarks,
                      let allPoints = landmarks.allPoints else {
                    print("Face detection or landmarks extraction failed.")
                    completion(false, nil)
                    return
                }

                let points = self.normalizedPoints(from: allPoints, boundingBox: firstFace.boundingBox)
                DispatchQueue.main.async {
                    self.faceEncodings[userId] = points
                    print("Face encoded successfully for user: \(userId)")
                    completion(true, points)
                }
            }

            do {
                try requestHandler.perform([faceDetectionRequest])
            } catch {
                print("Error performing face detection request: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false, nil)
                }
            }
        }
    }

    /// Normalizes facial landmark points based on the bounding box.
    private func normalizedPoints(from points: VNFaceLandmarkRegion2D, boundingBox: CGRect) -> [CGPoint] {
        return points.normalizedPoints.map { point in
            CGPoint(
                x: boundingBox.origin.x + point.x * boundingBox.size.width,
                y: boundingBox.origin.y + point.y * boundingBox.size.height
            )
        }
    }

    /// Calculates similarity between two sets of face encodings.
    func calculateSimilarity(metrics1: [Float], metrics2: [Float]) -> Float {
        guard metrics1.count == metrics2.count else { return 0 }

        var totalDistance: Float = 0.0
        for i in 0..<metrics1.count {
            let difference = metrics1[i] - metrics2[i]
            totalDistance += abs(difference)
        }

        return 1 - (totalDistance / Float(metrics1.count)) // Normalize similarity
    }
}
