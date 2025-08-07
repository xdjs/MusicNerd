import Foundation

@Observable
class AppSettings {
    static let shared = AppSettings()
    
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Settings Keys
    private enum Keys {
        static let sampleDuration = "sample_duration"
        static let showDebugInfo = "show_debug_info"
        static let useProductionServer = "use_production_server"
        static let cacheExpirationHours = "cache_expiration_hours"
    }
    
    // MARK: - Sample Duration Setting
    var sampleDuration: TimeInterval {
        get {
            let saved = userDefaults.double(forKey: Keys.sampleDuration)
            return saved > 0 ? saved : 3.0 // Default to 3 seconds
        }
        set {
            userDefaults.set(newValue, forKey: Keys.sampleDuration)
        }
    }
    
    // MARK: - Debug Settings
    var showDebugInfo: Bool {
        get {
            userDefaults.bool(forKey: Keys.showDebugInfo)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.showDebugInfo)
        }
    }
    
    // MARK: - Server Settings
    var useProductionServer: Bool {
        get {
            // Default to production server
            let defaultValue = true
            return userDefaults.object(forKey: Keys.useProductionServer) as? Bool ?? defaultValue
        }
        set {
            userDefaults.set(newValue, forKey: Keys.useProductionServer)
        }
    }
    
    var currentServerURL: String {
        return useProductionServer ? AppConfiguration.API.productionBaseURL : AppConfiguration.API.developmentBaseURL
    }
    
    // MARK: - Cache Settings
    var cacheExpirationHours: Double {
        get {
            let saved = userDefaults.double(forKey: Keys.cacheExpirationHours)
            return saved > 0 ? saved : 24.0 // Default to 24 hours
        }
        set {
            userDefaults.set(newValue, forKey: Keys.cacheExpirationHours)
        }
    }
    
    var cacheExpirationInterval: TimeInterval {
        return cacheExpirationHours * 60 * 60 // Convert hours to seconds
    }
    
    private init() {}
    
    // MARK: - Debug Methods
    
    func resetToDefaults() {
        userDefaults.removeObject(forKey: Keys.sampleDuration)
        userDefaults.removeObject(forKey: Keys.showDebugInfo)
        userDefaults.removeObject(forKey: Keys.useProductionServer)
        userDefaults.removeObject(forKey: Keys.cacheExpirationHours)
    }
}

// MARK: - Sample Duration Options
extension AppSettings {
    static let sampleDurationOptions: [TimeInterval] = [3, 5, 10, 15, 20]
    
    static func formatDuration(_ duration: TimeInterval) -> String {
        let seconds = Int(duration)
        return "\(seconds) second\(seconds == 1 ? "" : "s")"
    }
}

// MARK: - Cache Expiration Options
extension AppSettings {
    static let cacheExpirationOptions: [Double] = [1, 6, 12, 24, 48, 168] // 1h, 6h, 12h, 24h, 48h, 1 week
    
    static func formatCacheExpiration(_ hours: Double) -> String {
        if hours < 24 {
            let h = Int(hours)
            return "\(h) hour\(h == 1 ? "" : "s")"
        } else {
            let days = Int(hours / 24)
            return "\(days) day\(days == 1 ? "" : "s")"
        }
    }
}