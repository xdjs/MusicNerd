import AVFoundation
import Foundation

enum PermissionStatus {
    case notDetermined
    case granted
    case denied
    case restricted
}


protocol PermissionServiceProtocol {
    func requestMicrophonePermission() async throws -> PermissionStatus
    func checkMicrophonePermission() -> PermissionStatus
}

class PermissionService: PermissionServiceProtocol {
    
    func checkMicrophonePermission() -> PermissionStatus {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .undetermined:
            return .notDetermined
        case .granted:
            return .granted
        case .denied:
            return .denied
        @unknown default:
            return .denied
        }
    }
    
    func requestMicrophonePermission() async throws -> PermissionStatus {
        let currentStatus = checkMicrophonePermission()
        
        switch currentStatus {
        case .granted:
            return .granted
        case .denied:
            throw AppError.permissionError(.microphoneDenied)
        case .restricted:
            throw AppError.permissionError(.microphoneRestricted)
        case .notDetermined:
            break
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if granted {
                    continuation.resume(returning: .granted)
                } else {
                    continuation.resume(throwing: AppError.permissionError(.microphoneDenied))
                }
            }
        }
    }
}