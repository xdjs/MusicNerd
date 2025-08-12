import Foundation
import MusicKit
import Combine
import AVFoundation

@MainActor
protocol AppleMusicServiceProtocol: AnyObject {
    func requestAuthorization() async -> MusicAuthorization.Status
    var authorizationStatus: MusicAuthorization.Status { get }
    func currentSubscription() async -> MusicSubscription?
    // Lookup helpers
    func song(fromAppleMusicID id: String) async -> Song?
    func searchSong(title: String, artist: String) async -> Song?
    func previewURL(for song: Song) -> URL?
    // Preview playback controls
    func playPreview(url: URL)
    func pause()
    func resume()
    var isPlayingPreview: Bool { get }
    var previewProgress: Double { get }
}

@MainActor
final class AppleMusicService: AppleMusicServiceProtocol, ObservableObject {
    @Published private(set) var authorizationStatus: MusicAuthorization.Status = MusicAuthorization.currentStatus
    private var cancellables: Set<AnyCancellable> = []
    private var player: AVPlayer?
    private var boundaryObserver: Any?
    private var periodicObserver: Any?
    private var endObserverCancellable: AnyCancellable?
    @Published private(set) var isPlayingPreview: Bool = false
    @Published private(set) var previewProgress: Double = 0

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

    // MARK: - Lookup
    func song(fromAppleMusicID id: String) async -> Song? {
        do {
            let musicId = MusicItemID(rawValue: id)
            let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: musicId)
            let response = try await request.response()
            return response.items.first
        } catch {
            return nil
        }
    }

    func searchSong(title: String, artist: String) async -> Song? {
        do {
            let term = "\(title) \(artist)"
            var request = MusicCatalogSearchRequest(term: term, types: [Song.self])
            request.limit = 5
            let response = try await request.response()
            return response.songs.first
        } catch {
            return nil
        }
    }

    func previewURL(for song: Song) -> URL? {
        // Prefer the first available preview asset
        return song.previewAssets?.first?.url
    }

    // MARK: - Preview Playback
    func playPreview(url: URL) {
        // Clean up previous observer
        if let boundaryObserver {
            player?.removeTimeObserver(boundaryObserver)
            self.boundaryObserver = nil
        }
        if let periodicObserver {
            player?.removeTimeObserver(periodicObserver)
            self.periodicObserver = nil
        }
        endObserverCancellable?.cancel()
        endObserverCancellable = nil
        player?.pause()
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        // Ensure playback category is correct for preview
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
        player?.play()
        isPlayingPreview = true
        previewProgress = 0
        
        // Auto-stop at 30 seconds (if item is longer)
        let boundaryTime = CMTime(seconds: 30, preferredTimescale: 1)
        boundaryObserver = player?.addBoundaryTimeObserver(forTimes: [NSValue(time: boundaryTime)], queue: .main) { [weak self] in
            guard let self else { return }
            self.player?.pause()
            self.isPlayingPreview = false
            self.previewProgress = 0
        }

        // Periodic progress updates (normalize to 30s max)
        let interval = CMTime(seconds: 0.2, preferredTimescale: 10)
        periodicObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            let currentSeconds = CMTimeGetSeconds(time)
            let normalized = max(0, min(1, currentSeconds / 30.0))
            self.previewProgress = normalized
        }

        // Observe item end (for previews shorter than 30s)
        endObserverCancellable = NotificationCenter.default
            .publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.isPlayingPreview = false
                self.previewProgress = 0
            }
    }

    func pause() {
        player?.pause()
        isPlayingPreview = false
        // Keep progress but stop advancing
    }

    func resume() {
        player?.play()
        isPlayingPreview = true
    }
}
