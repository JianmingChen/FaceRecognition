import SwiftUI

func uploadImageForUser(image: UIImage, userID: String ) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        guard userID != "" else { return }
        
        let url = URL(string: "http://localhost:3000/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        let filename = "\(userID)"
        let fieldName = "photo"
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename).jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
            } else {
                print("Upload successful!")
            }
        }.resume()
    }
    
    
    
    
func downloadImage(filename: String, completion: @escaping (UIImage?) -> Void) {
    let url = URL(string: "http://localhost:3000/download/\(filename).jpg")!
    
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let data = data, let image = UIImage(data: data) {
            DispatchQueue.main.async {
                completion(image)
            }
        } else {
            completion(nil)
        }
    }.resume()
}
    

