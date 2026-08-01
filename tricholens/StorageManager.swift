import Foundation
import UIKit

class StorageManager {
    static let shared = StorageManager()
    private init() {
        // Singleton initialization
    }
    
    private var currentHistoryKey: String {
        if let data = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            return "diagnosis_history_\(user.id)"
        }
        return "diagnosis_history"
    }
    private let userKey = "logged_in_user"
    
    // MARK: - History
    
    func saveHistory(item: HistoryItem) {
        var items = getHistory()
        items.insert(item, at: 0)
        saveHistoryList(items)
    }
    
    func getHistory() -> [HistoryItem] {
        let key = currentHistoryKey
        if let data = UserDefaults.standard.data(forKey: key) {
            do {
                return try JSONDecoder().decode([HistoryItem].self, from: data)
            } catch {
                print("Error decoding history: \(error)")
            }
        }
        
        if key != "diagnosis_history", let legacyData = UserDefaults.standard.data(forKey: "diagnosis_history") {
            do {
                let items = try JSONDecoder().decode([HistoryItem].self, from: legacyData)
                syncHistoryList(items)
                return items
            } catch {
                print("Error decoding legacy history: \(error)")
            }
        }
        
        return []
    }
    
    func syncHistoryList(_ items: [HistoryItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: currentHistoryKey)
        } catch {
            print("Error encoding history: \(error)")
        }
    }
    
    private func saveHistoryList(_ items: [HistoryItem]) {
        syncHistoryList(items)
    }
    
    func deleteHistory(item: HistoryItem) {
        var items = getHistory()
        items.removeAll { $0.id == item.id }
        saveHistoryList(items)
        
        // Also delete the image file from disk if it's a local file
        guard !item.imageUri.hasPrefix("http"),
              item.imageUri != "local_dataset",
              item.imageUri != "image",
              !item.imageUri.isEmpty else { return }
        
        let fileManager = FileManager.default
        if let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = docs.appendingPathComponent(item.imageUri)
            try? fileManager.removeItem(at: fileURL)
        }
    }
    
    func syncHistoryWithServerItems(_ serverItems: [HistoryItem]) {
        var localItems = getHistory()
        var updated = false
        
        for sItem in serverItems {
            let exists = localItems.contains { localItem in
                return (localItem.id == sItem.id && sItem.id != nil) || 
                       (localItem.timestamp == sItem.timestamp && localItem.condition == sItem.condition)
            }
            if !exists {
                localItems.append(sItem)
                updated = true
            }
        }
        
        if updated {
            localItems.sort { $0.timestamp > $1.timestamp }
            syncHistoryList(localItems)
        }
    }
    
    // MARK: - User Session
    
    func saveUser(_ user: User) {
        do {
            let data = try JSONEncoder().encode(user)
            UserDefaults.standard.set(data, forKey: userKey)
            if let c = user.country, !c.isEmpty {
                UserDefaults.standard.set(c, forKey: "country_cache_\(user.email)")
            }
        } catch {
            print("Error encoding user: \(error)")
        }
    }
    
    func getUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: userKey) else {
            return nil
        }
        
        do {
            var decodedUser = try JSONDecoder().decode(User.self, from: data)
            if let cached = UserDefaults.standard.string(forKey: "country_cache_\(decodedUser.email)") {
                decodedUser.country = cached
            }
            return decodedUser
        } catch {
            print("Error decoding user: \(error)")
            return nil
        }
    }
    
    func clearUser() {
        UserDefaults.standard.removeObject(forKey: userKey)
        UserDefaults.standard.removeObject(forKey: "diagnosis_history")
    }
    
    // MARK: - Image Persistence
    
    func saveImage(image: UIImage, fileName: String) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileName
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    func loadImage(fileName: String) -> UIImage? {
        // If it's a remote URL or placeholder, we can't load it this way
        if fileName.hasPrefix("http") || fileName == "local_dataset" || fileName == "image" {
            return nil
        }
        
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            return UIImage(contentsOfFile: fileURL.path)
        }
        
        return nil
    }
    
    func getImageUrl(fileName: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    func cleanupLegacyHistory() {
        var items = getHistory()
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        
        items = items.filter { item in
            // Keep if it's a remote URL
            if item.imageUri.hasPrefix("http") {
                return true
            }
            
            // Keep if it's from local dataset (if applicable)
            if item.imageUri == "local_dataset" {
                return true
            }
            
            // Filter out old placeholders
            if item.imageUri == "image" || item.imageUri == "scalp" || item.imageUri.isEmpty {
                return false
            }
            
            // Keep if the local file actually exists
            if let docs = documentsDirectory {
                let fileURL = docs.appendingPathComponent(item.imageUri)
                return fileManager.fileExists(atPath: fileURL.path)
            }
            
            return false
        }
        
        saveHistoryList(items)
    }
}
