import Foundation

enum AppError: LocalizedError, Equatable {
    case shazamError(ShazamError)
    case networkError(NetworkError)
    case storageError(StorageError)
    case enrichmentError(EnrichmentError)
    case permissionError(PermissionError)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .shazamError(let error):
            return error.localizedDescription
        case .networkError(let error):
            return error.localizedDescription
        case .storageError(let error):
            return error.localizedDescription
        case .enrichmentError(let error):
            return error.localizedDescription
        case .permissionError(let error):
            return error.localizedDescription
        case .unknown(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .shazamError(let error):
            return error.recoverySuggestion
        case .networkError(let error):
            return error.recoverySuggestion
        case .storageError(let error):
            return error.recoverySuggestion
        case .enrichmentError(let error):
            return error.recoverySuggestion
        case .permissionError(let error):
            return error.recoverySuggestion
        case .unknown:
            return "Please try again or contact support if the problem persists."
        }
    }
}

enum ShazamError: LocalizedError, Equatable {
    case noMatch
    case noMicrophonePermission
    case audioSessionFailed
    case recognitionFailed(String)
    case invalidSignature
    
    var errorDescription: String? {
        switch self {
        case .noMatch:
            return "No song match found"
        case .noMicrophonePermission:
            return "Microphone access required"
        case .audioSessionFailed:
            return "Audio session failed to start"
        case .recognitionFailed(let message):
            return "Recognition failed: \(message)"
        case .invalidSignature:
            return "Invalid audio signature"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noMatch:
            return "Try playing the song louder or getting closer to the source."
        case .noMicrophonePermission:
            return "Please enable microphone access in Settings to identify music."
        case .audioSessionFailed:
            return "Check that no other apps are using the microphone and try again."
        case .recognitionFailed:
            return "Make sure you're in a quiet environment and try again."
        case .invalidSignature:
            return "Please try recording again."
        }
    }
}

enum NetworkError: LocalizedError, Equatable {
    case noConnection
    case timeout
    case invalidResponse
    case serverError(Int)
    case rateLimited
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let code):
            return "Server error (\(code))"
        case .rateLimited:
            return "Too many requests"
        case .invalidURL:
            return "Invalid URL"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Check your internet connection and try again."
        case .timeout:
            return "Check your connection speed and try again."
        case .invalidResponse:
            return "Please try again later."
        case .serverError:
            return "The service is temporarily unavailable. Please try again later."
        case .rateLimited:
            return "Please wait a moment before trying again."
        case .invalidURL:
            return "Please contact support."
        }
    }
}

enum StorageError: LocalizedError, Equatable {
    case saveFailed
    case loadFailed
    case deleteFailed
    case migrationFailed
    case diskFull
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save data"
        case .loadFailed:
            return "Failed to load data"
        case .deleteFailed:
            return "Failed to delete data"
        case .migrationFailed:
            return "Failed to migrate data"
        case .diskFull:
            return "Not enough storage space"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .saveFailed, .loadFailed, .deleteFailed:
            return "Please try again."
        case .migrationFailed:
            return "Please restart the app. Contact support if the problem persists."
        case .diskFull:
            return "Free up some storage space and try again."
        }
    }
}

enum EnrichmentError: LocalizedError, Equatable {
    case noData
    case invalidData
    case processingFailed
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .noData:
            return "No enrichment data available"
        case .invalidData:
            return "Invalid enrichment data"
        case .processingFailed:
            return "Failed to process enrichment"
        case .quotaExceeded:
            return "Enrichment quota exceeded"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noData:
            return "Some songs may not have additional information available."
        case .invalidData:
            return "Please try again."
        case .processingFailed:
            return "Please try again later."
        case .quotaExceeded:
            return "Please try again tomorrow or upgrade your plan."
        }
    }
}

enum PermissionError: LocalizedError, Equatable {
    case microphoneDenied
    case microphoneRestricted
    case microphoneNotDetermined
    
    var errorDescription: String? {
        switch self {
        case .microphoneDenied:
            return "Microphone access denied"
        case .microphoneRestricted:
            return "Microphone access restricted"
        case .microphoneNotDetermined:
            return "Microphone permission required"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .microphoneDenied:
            return "Please enable microphone access in Settings > Privacy & Security > Microphone > TrackNerd."
        case .microphoneRestricted:
            return "Microphone access is restricted by device policy."
        case .microphoneNotDetermined:
            return "Please allow microphone access to identify music."
        }
    }
}

typealias Result<T> = Swift.Result<T, AppError>
