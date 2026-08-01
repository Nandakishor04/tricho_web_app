import Foundation
import UIKit
import CoreML

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    // If using the iOS Simulator, localhost works fine.
    // If using a physical device, replace with your Mac's Local IP (e.g., 192.168.x.x)
    // Production Server:
    let baseURL = "http://172.25.80.255:8118/"
    enum NetworkError: Error {
        case invalidURL
        case noData
        case decodingError
        case serverError(String)
    }    
    // MARK: - Auth
  
    func login(username: String, password: String, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        let urlString = "\(baseURL)login"
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParameters = [
            "username": username,
            "password": password
        ]
        
        request.httpBody = bodyParameters.asURLQueryItems().data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    func signup(name: String, email: String, mobile: String, dob: String, gender: String, age: String, country: String, password: String, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        let urlString = "\(baseURL)signup"
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParameters = [
            "name": name,
            "email": email,
            "mobile": mobile,
            "dob": dob,
            "gender": gender,
            "age": age,
            "country": country,
            "password": password
        ]
        
        request.httpBody = bodyParameters.asURLQueryItems().data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    func updateProfile(email: String, name: String, mobile: String, dob: String, gender: String, age: String, country: String, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        let urlString = "\(baseURL)update_profile"
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParameters = [
            "email": email,
            "name": name,
            "mobile": mobile,
            "dob": dob,
            "gender": gender,
            "age": age,
            "country": country
        ]
        
        request.httpBody = bodyParameters.asURLQueryItems().data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    func checkMobile(mobile: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let urlString = "\(baseURL)check_mobile"
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParameters = ["mobile": mobile]
        request.httpBody = bodyParameters.asURLQueryItems().data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    completion(.success(json))
                } else {
                    completion(.failure(NetworkError.decodingError))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func sendOTP(email: String, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        let urlString = "\(baseURL)send_email_otp"
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let bodyParameters = ["email": email]
        request.httpBody = bodyParameters.asURLQueryItems().data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    func verifyOTP(email: String, otp: String, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        let urlString = "\(baseURL)verify_email_otp"
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let bodyParameters = ["email": email, "otp": otp]
        request.httpBody = bodyParameters.asURLQueryItems().data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    func resetPassword(email: String, password: String, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        let urlString = "\(baseURL)reset_password"
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParameters = [
            "email": email,
            "password": password
        ]
        
        request.httpBody = bodyParameters.asURLQueryItems().data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            self.handleResponse(data: data, response: response, error: error, completion: completion)
        }.resume()
    }
    
    // MARK: - Diagnose (Multipart)
    
    func diagnose(image: UIImage, 
                  patientName: String, 
                  age: String, 
                  gender: String, 
                  familyHistory: String, 
                  duration: String, 
                  treatmentHistory: String? = nil,
                  doctorComments: String? = nil,
                  completion: @escaping (Result<HistoryItem, Error>) -> Void) {
        
        guard let url = URL(string: "\(baseURL)diagnose") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120.0
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // v11.0: Send standard resolution to server. Server now handles unified cropping and normalization.
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])))
            return
        }
        
        var body = Data()
        
        // Form Fields
        let fields = [
            "patient_name": patientName,
            "age": age,
            "gender": gender,
            "family_history": familyHistory,
            "duration": duration,
            "treatment_history": treatmentHistory ?? "",
            "doctor_comments": doctorComments ?? ""
        ]
        
        for (key, value) in fields {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        if let user = StorageManager.shared.getUser() {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(user.id)\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? String, (status == "success" || status == "valid") {
                    
                    let id = json["id"] as? String
                    let imagePath = json["image_url"] as? String ?? "image"
                    
                    // Unified Architecture: Use EXACT backend medical metrics from explicit JSON fields.
                    // No client-side parsing of diagnosis strings.
                    let condition = json["condition"] as? String ?? "Analysis Result"
                    let densityStr = json["density"] as? String ?? "--"
                    let ratioVal = json["ratio"] as? String ?? "--"
                    let vellusVal = json["vellus_hair"] as? String ?? "--"
                    let obsStr = json["observation"] as? String ?? ""
                    let signsPresent = json["signs_present"] as? String ?? ""
                    
                    // Ratio convention: "ratio|vellus" for local storage/history logic
                    let finalRatio = "\(ratioVal)|\(vellusVal)"
                    
                    // Patient Details (Echoed from Server)
                    let pName = json["patient_name"] as? String ?? patientName
                    let pAge = json["age"] as? String ?? age
                    let pGender = json["gender"] as? String ?? gender
                    let pFam = json["family_history"] as? String ?? familyHistory
                    let pDur = json["duration"] as? String ?? duration
                    let pTreat = json["treatment_history"] as? String ?? (treatmentHistory ?? "")
                    let pDoc = json["doctor_comments"] as? String ?? (doctorComments ?? "")

                    let item = HistoryItem(
                        id: id,
                        imageUri: imagePath,
                        density: densityStr,
                        ratio: finalRatio,
                        condition: condition,
                        observation: obsStr,
                        patientName: pName,
                        patientAge: pAge,
                        patientGender: pGender,
                        patientFamilyHistory: pFam,
                        patientDuration: pDur,
                        patientTreatmentHistory: pTreat,
                        patientSignsPresent: signsPresent,
                        doctorComments: pDoc
                    )
                    
                    completion(.success(item))
                } else {
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                    let message = json?["message"] as? String ?? "Diagnosis failed"
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: message])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchHistory(completion: @escaping (Result<[HistoryItem], Error>) -> Void) {
        guard let user = StorageManager.shared.getUser() else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
        
        guard let url = URL(string: "\(baseURL)get_history") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "user_id=\(user.id)".data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? String, status == "success",
                   let historyArray = json["history"] as? [[String: Any]] {
                    
                    let items = historyArray.compactMap { dict -> HistoryItem? in
                        let idInt = dict["id"] as? Int
                        let id = idInt != nil ? "\(idInt!)" : (dict["id"] as? String ?? "")
                        let imagePath = dict["image_path"] as? String ?? ""
                        
                        // Unified Architecture: Use explicit JSON fields provided by backend's history endpoint
                        let density = dict["density"] as? String ?? "--"
                        let ratioVal = dict["ratio"] as? String ?? "--"
                        let vellusVal = dict["vellus_hair"] as? String ?? (dict["vellus"] as? String ?? "--")
                        let condition = dict["condition"] as? String ?? "--"
                        let observation = dict["observation"] as? String ?? "--"
                        let ratio = "\(ratioVal)|\(vellusVal)"
                        
                        return HistoryItem(
                            id: id, 
                            imageUri: imagePath, 
                            density: density, 
                            ratio: ratio, 
                            condition: condition, 
                            observation: observation, 
                            timestamp: dict["diagnosis_date"] as? String,
                            patientName: dict["patient_name"] as? String,
                            patientAge: dict["age"] as? String,
                            patientGender: dict["gender"] as? String,
                            patientFamilyHistory: dict["family_history"] as? String,
                            patientDuration: dict["duration"] as? String,
                            patientTreatmentHistory: dict["treatment_history"] as? String,
                            patientSignsPresent: dict["signs_present"] as? String,
                            doctorComments: dict["doctor_comments"] as? String
                        )
                    }
                    completion(.success(items))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch history"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func saveHistoryToServer(item: HistoryItem, completion: @escaping (Result<Void, Error>) -> Void) {
        // saveHistoryToServer is deprecated in v11.0 because 'diagnose' handles server-side saving automatically.
        // This remains only for manual sync if required.
        guard let user = StorageManager.shared.getUser() else { return }
        guard let url = URL(string: "\(baseURL)save_history") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var components = URLComponents()
        var postItems = [URLQueryItem]()
        postItems.append(URLQueryItem(name: "user_id", value: "\(user.id)"))
        postItems.append(URLQueryItem(name: "image_path", value: item.imageUri))
        postItems.append(URLQueryItem(name: "density", value: item.density))
        postItems.append(URLQueryItem(name: "ratio", value: item.displayRatio))
        postItems.append(URLQueryItem(name: "vellus_hair", value: item.vellusPercentage.replacingOccurrences(of: "Vellus Hair : ", with: "")))
        postItems.append(URLQueryItem(name: "condition", value: item.condition))
        postItems.append(URLQueryItem(name: "observation", value: item.observation))
        
        components.queryItems = postItems
        request.httpBody = components.query?.data(using: .utf8)
        URLSession.shared.dataTask(with: request).resume()
    }
    
    // MARK: - Helper
    private func handleResponse<T: Decodable>(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<T, Error>) -> Void) {
        if let error = error {
            completion(.failure(error))
            return
        }
        guard let data = data else {
            completion(.failure(NetworkError.noData))
            return
        }
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            completion(.success(decoded))
        } catch {
            completion(.failure(error))
        }
    }

    func deleteHistoryItem(id: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: baseURL + "delete_history") else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["id": id]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else {
                completion(false)
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let status = json["status"] as? String {
                    completion(status == "success")
                } else {
                    completion(false)
                }
            } catch {
                completion(false)
            }
        }.resume()
    }
}

extension Dictionary where Key == String, Value == String {
    func asURLQueryItems() -> String {
        return self.map { key, value in
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(key)=\(encodedValue)"
        }.joined(separator: "&")
    }
}
extension UIImage {
    func preprocessedForDiagnosis() -> UIImage? {
        let sideLength = min(self.size.width, self.size.height)
        let xOffset = (self.size.width - sideLength) / 2.0
        let yOffset = (self.size.height - sideLength) / 2.0
        let cropRect = CGRect(x: xOffset, y: yOffset, width: sideLength, height: sideLength)
        
        guard let sourceCGImage = self.cgImage else { return nil }
        
        // Adjust for scale/orientation if needed
        let croppedCGImage = sourceCGImage.cropping(to: cropRect)
        
        // Resize to a standard 512x512 for consistent backend processing
        let targetSize = CGSize(width: 512, height: 512)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        
        return renderer.image { context in
            if let image = croppedCGImage {
                UIImage(cgImage: image).draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }
    }
}
