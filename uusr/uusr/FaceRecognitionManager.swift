import Vision
import CoreML
import UIKit

class FaceRecognitionManager {
    static let shared = FaceRecognitionManager()

    private var model: VNCoreMLModel?

    private init() {
        do {
            let mlModel = try FaceAuth(configuration: MLModelConfiguration()) // Load FaceAuth.mlmodel
            model = try VNCoreMLModel(for: mlModel.model) // Convert to VNCoreMLModel
        } catch {
            print("Error loading model: \(error)")
        }
    }

    // Use Core ML model to extract face embedding
    func getEmbedding(from image: UIImage, completion: @escaping ([Float]?) -> Void) {
        guard let cgImage = image.cgImage else {
            print("Image conversion to CGImage failed.")
            completion(nil)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNCoreMLRequest(model: self.model!) { request, error in
                guard error == nil,
                      let observations = request.results as? [VNCoreMLFeatureValueObservation],
                      let firstFace = observations.first else {
                    print("Error during face encoding.")
                    completion(nil)
                    return
                }

                // Get the embedding
                if let embedding = firstFace.featureValue.multiArrayValue {
                    // Extract values from MLMultiArray
                    var faceEncoding: [Float] = []
                    for i in 0..<embedding.count {
                        let value = embedding[i].floatValue
                        faceEncoding.append(value)
                    }
                    DispatchQueue.main.async {
                        print("Face encoding successful.")
                        completion(faceEncoding) // Return the embedding
                    }
                } else {
                    DispatchQueue.main.async {
                        print("No face encoding found.")
                        completion(nil)
                    }
                }
            }

            do {
                try requestHandler.perform([request])
            } catch {
                print("Error performing face encoding request: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }

    // Calculate similarity between two embeddings
    func calculateSimilarity(metrics1: [Float], metrics2: [Float]) -> Float {
        guard metrics1.count == metrics2.count else { return 0 }

        var totalDistance: Float = 0.0
        for i in 0..<metrics1.count {
            let difference = metrics1[i] - metrics2[i]
            totalDistance += abs(difference)
        }

        return 1 - (totalDistance / Float(metrics1.count)) // Normalize similarity
    }

    // Cosine similarity between two vectors
    func cosineSimilarity(a: [Float], b: [Float]) -> Float {
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))

        // To avoid division by zero, we ensure that magnitude is not zero
        if magnitudeA == 0 || magnitudeB == 0 {
            return 0
        }

        return dotProduct / (magnitudeA * magnitudeB)  // Cosine similarity
    }
}
