import Foundation

class DataCache {
    static let shared = DataCache()
    
    private let userDefaults = UserDefaults.standard
    private let cacheKeyPrefix = "MutualFunds_"
    private let expirationTimeInterval: TimeInterval = 86400 // 24 hours (daily NAV updates)
    
    private init() {}
    
    // MARK: - Fund List Caching
    
    func cacheFundsList(_ funds: [MutualFund]) {
        do {
            let data = try JSONEncoder().encode(funds)
            let cacheEntry = CacheEntry(data: data, timestamp: Date())
            let encodedEntry = try JSONEncoder().encode(cacheEntry)
            
            userDefaults.set(encodedEntry, forKey: "\(cacheKeyPrefix)fundsList")
        } catch {
            print("Failed to cache funds list: \(error)")
        }
    }
    
    func getCachedFundsList() -> [MutualFund]? {
        guard let data = userDefaults.data(forKey: "\(cacheKeyPrefix)fundsList") else {
            return nil
        }
        
        do {
            let cacheEntry = try JSONDecoder().decode(CacheEntry.self, from: data)
            
            // Check if cache is expired
            if Date().timeIntervalSince(cacheEntry.timestamp) > expirationTimeInterval {
                return nil
            }
            
            let funds = try JSONDecoder().decode([MutualFund].self, from: cacheEntry.data)
            return funds
        } catch {
            print("Failed to decode cached funds list: \(error)")
            return nil
        }
    }
    
    // MARK: - Fund History Caching
    
    func cacheFundHistory(_ history: FundHistory, for schemeCode: String) {
        do {
            let data = try JSONEncoder().encode(history)
            let cacheEntry = CacheEntry(data: data, timestamp: Date())
            let encodedEntry = try JSONEncoder().encode(cacheEntry)
            
            userDefaults.set(encodedEntry, forKey: "\(cacheKeyPrefix)history_\(schemeCode)")
        } catch {
            print("Failed to cache fund history for \(schemeCode): \(error)")
        }
    }
    
    func getCachedFundHistory(for schemeCode: String) -> FundHistory? {
        guard let data = userDefaults.data(forKey: "\(cacheKeyPrefix)history_\(schemeCode)") else {
            return nil
        }
        
        do {
            let cacheEntry = try JSONDecoder().decode(CacheEntry.self, from: data)
            
            // Check if cache is expired (daily NAV updates)
            if Date().timeIntervalSince(cacheEntry.timestamp) > expirationTimeInterval { // 24 hours
                return nil
            }
            
            let history = try JSONDecoder().decode(FundHistory.self, from: cacheEntry.data)
            return history
        } catch {
            print("Failed to decode cached fund history for \(schemeCode): \(error)")
            return nil
        }
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix(cacheKeyPrefix) {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
    
    func clearExpiredCache() {
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix(cacheKeyPrefix) {
                if let data = userDefaults.data(forKey: key) {
                    do {
                        let cacheEntry = try JSONDecoder().decode(CacheEntry.self, from: data)
                        if Date().timeIntervalSince(cacheEntry.timestamp) > expirationTimeInterval {
                            userDefaults.removeObject(forKey: key)
                        }
                    } catch {
                        // If we can't decode, remove the corrupted entry
                        userDefaults.removeObject(forKey: key)
                    }
                }
            }
        }
    }
    
    func getCacheSize() -> String {
        let keys = userDefaults.dictionaryRepresentation().keys
        var totalSize: Int = 0
        
        for key in keys {
            if key.hasPrefix(cacheKeyPrefix) {
                if let data = userDefaults.data(forKey: key) {
                    totalSize += data.count
                }
            }
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalSize))
    }
}

private struct CacheEntry: Codable {
    let data: Data
    let timestamp: Date
}