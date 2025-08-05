import Foundation
import AVFoundation
import ShazamKit

enum RecognitionState {
    case idle
    case listening
    case processing
    case success(SongMatch)
    case failure(AppError)
}

protocol ShazamServiceDelegate: AnyObject {
    func shazamService(_ service: ShazamService, didChangeState state: RecognitionState)
}

class ShazamService: NSObject, ShazamServiceProtocol {
    weak var delegate: ShazamServiceDelegate?
    
    private let audioEngine = AVAudioEngine()
    // TODO: Uncomment when ShazamKit is added to project
    // private var session: SHSession?
    // private var signatureGenerator: SHSignatureGenerator?
    
    private var currentState: RecognitionState = .idle {
        didSet {
            delegate?.shazamService(self, didChangeState: currentState)
        }
    }
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    deinit {
        stopListening()
    }
    
    // MARK: - ShazamServiceProtocol
    
    func startListening() async -> Result<SongMatch> {
        do {
            try await requestMicrophonePermission()
            // TODO: Replace with actual ShazamKit implementation
            return await mockRecognition()
        } catch {
            let appError = error as? AppError ?? AppError.shazamError(.recognitionFailed(error.localizedDescription))
            currentState = .failure(appError)
            return .failure(appError)
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        // TODO: Uncomment when ShazamKit is added
        // session = nil
        // signatureGenerator = nil
        currentState = .idle
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func requestMicrophonePermission() async throws {
        let permissionService = PermissionService()
        let status = try await permissionService.requestMicrophonePermission()
        
        if status != .granted {
            throw AppError.shazamError(.noMicrophonePermission)
        }
    }
    
    // MARK: - Mock Implementation (TODO: Replace with ShazamKit)
    
    private func mockRecognition() async -> Result<SongMatch> {
        currentState = .listening
        
        // Simulate listening for 2 seconds
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        currentState = .processing
        
        // Simulate processing for 1 second
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock recognition result (simulate finding a song 70% of the time)
        if Bool.random() && Double.random(in: 0...1) > 0.3 {
            let mockSongs = [
                ("Bohemian Rhapsody", "Queen", "A Night at the Opera"),
                ("Hotel California", "Eagles", "Hotel California"),
                ("Imagine", "John Lennon", "Imagine"),
                ("Sweet Child O' Mine", "Guns N' Roses", "Appetite for Destruction"),
                ("Billie Jean", "Michael Jackson", "Thriller")
            ]
            
            let randomSong = mockSongs.randomElement()!
            let match = SongMatch(
                title: randomSong.0,
                artist: randomSong.1,
                album: randomSong.2,
                albumArtURL: nil,
                appleMusicID: nil,
                shazamID: UUID().uuidString
            )
            
            currentState = .success(match)
            return .success(match)
        } else {
            let error = AppError.shazamError(.noMatch)
            currentState = .failure(error)
            return .failure(error)
        }
    }
}

// TODO: Uncomment when ShazamKit is added to project
/*
// MARK: - SHSessionDelegate

extension ShazamService: SHSessionDelegate {
    func session(_ session: SHSession, didFind match: SHMatch) {
        stopListening()
        
        guard let mediaItem = match.mediaItems.first else {
            let error = AppError.shazamError(.noMatch)
            currentState = .failure(error)
            recognitionContinuation?.resume(returning: .failure(error))
            recognitionContinuation = nil
            return
        }
        
        // Parse metadata from ShazamKit response
        let songMatch = parseSongMatch(from: mediaItem)
        currentState = .success(songMatch)
        recognitionContinuation?.resume(returning: .success(songMatch))
        recognitionContinuation = nil
    }
    
    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature) {
        stopListening()
        
        let error = AppError.shazamError(.noMatch)
        currentState = .failure(error)
        recognitionContinuation?.resume(returning: .failure(error))
        recognitionContinuation = nil
    }
    
    func session(_ session: SHSession, didFailWithError error: Error) {
        stopListening()
        
        let appError = AppError.shazamError(.recognitionFailed(error.localizedDescription))
        currentState = .failure(appError)
        recognitionContinuation?.resume(returning: .failure(appError))
        recognitionContinuation = nil
    }
    
    // MARK: - Metadata Parsing
    
    private func parseSongMatch(from mediaItem: SHMediaItem) -> SongMatch {
        let title = mediaItem.title ?? "Unknown Title"
        let artist = mediaItem.artist ?? "Unknown Artist"
        let albumArtURL = mediaItem.artworkURL?.absoluteString
        let appleMusicID = mediaItem.appleMusicID
        let shazamID = mediaItem.shazamID
        
        return SongMatch(
            id: UUID(),
            title: title,
            artist: artist,
            album: mediaItem.subtitle,
            albumArtURL: albumArtURL,
            appleMusicID: appleMusicID,
            shazamID: shazamID,
            matchedAt: Date(),
            enrichmentData: nil
        )
    }
}
*/