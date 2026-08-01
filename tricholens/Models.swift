import Foundation

// MARK: - User & Auth

struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let mobile: String
    let dob: String?
    let gender: String?
    let age: String?
    var country: String?
}

struct AuthResponse: Codable {
    let status: String
    let message: String
    let user: User?
}

struct HistoryItem: Codable, Identifiable {
    var id: String
    let imageUri: String
    let density: String
    let ratio: String
    let condition: String
    let observation: String
    let timestamp: String
    let timestampMillis: Int64
    
    // Patient Details (v9.2)
    let patientName: String?
    let patientAge: String?
    let patientGender: String?
    let patientFamilyHistory: String?
    let patientDuration: String?
    let patientTreatmentHistory: String?
    let patientSignsPresent: String?
    let doctorComments: String?
    
    init(id: String? = nil, 
         imageUri: String, 
         density: String, 
         ratio: String, 
         condition: String, 
         observation: String, 
         timestamp: String? = nil,
         patientName: String? = nil,
         patientAge: String? = nil,
         patientGender: String? = nil,
         patientFamilyHistory: String? = nil,
         patientDuration: String? = nil,
         patientTreatmentHistory: String? = nil,
         patientSignsPresent: String? = nil,
         doctorComments: String? = nil) {
        
        let now = Date()
        self.id = id ?? "\(Int64(now.timeIntervalSince1970 * 1000))"
        self.imageUri = imageUri
        self.density = density
        self.ratio = ratio
        self.condition = condition
        self.observation = observation
        self.timestampMillis = Int64(now.timeIntervalSince1970 * 1000)
        
        // Patient Details
        self.patientName = patientName
        self.patientAge = patientAge
        self.patientGender = patientGender
        self.patientFamilyHistory = patientFamilyHistory
        self.patientDuration = patientDuration
        self.patientTreatmentHistory = patientTreatmentHistory
        self.patientSignsPresent = patientSignsPresent
        self.doctorComments = doctorComments
        
        if let ts = timestamp {
            self.timestamp = ts
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM yyyy  hh:mm a"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            self.timestamp = formatter.string(from: now)
        }
    }
    
    // The ratio field now natively receives "ratioVal|vellusVal" from NetworkManager
    var vellusPercentage: String {
        let parts = ratio.components(separatedBy: "|")
        if parts.count == 2 {
            return "Vellus Hair : \(parts[1])"
        }
        return "Vellus Hair : N/A"
    }

    var displayRatio: String {
        let parts = ratio.components(separatedBy: "|")
        return parts[0]
    }
    
    var imageUrl: URL? {
        if imageUri.hasPrefix("http") {
            return URL(string: imageUri)
        }
        // Clean up: handle absolute paths by extracting filename
        let filename = imageUri.components(separatedBy: "/").last ?? imageUri
        if filename.isEmpty { return nil }
        // Match the backend's new images/ route
        return URL(string: NetworkManager.shared.baseURL + "images/" + filename)
    }
}
