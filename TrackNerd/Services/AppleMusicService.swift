import Foundation
import MusicKit
import Combine

protocol AppleMusicServiceProtocol: AnyObject {
    func requestAuthorization() async -> MusicAuthorization.Status
    var authorizationStatus: MusicAuthorization.Status { get }
    func currentSubscription() async -> MusicSubscription?
}

final class AppleMusicService: AppleMusicServiceProtocol, ObservableObject {
    @Published private(set) var authorizationStatus: MusicAuthorization.Status = MusicAuthorization.currentStatus
    private var cancellables: Set<AnyCancellable> = []

    func requestAuthorization() async -> MusicAuthorization.Status {
        // If already determined, return current status
        let current = MusicAuthorization.currentStatus
        if current != .notDetermined {
            authorizationStatus = current
            return current
        }
        let status = await MusicAuthorization.request()
        authorizationStatus = status
        return status
    }

    func currentSubscription() async -> MusicSubscription? {
        do {
            return try await MusicSubscription.current
        } catch {
            return nil
        }
    }
}
