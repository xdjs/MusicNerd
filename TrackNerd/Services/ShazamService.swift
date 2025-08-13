import Foundation
import AVFoundation
import ShazamKit
import UIKit

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

enum RecognitionState {
    case idle
    case listening
    case processing
    case success(SongMatch)
    case failure(AppError)
}

extension RecognitionState: CustomStringConvertible {
    var description: String {
        switch self {
        case .idle:
            return "idle"
        case .listening:
            return "listening"
        case .processing:
            return "processing"
        case .success(let match):
            return "success(\(match.title) by \(match.artist))"
        case .failure(let error):
            return "failure(\(error.localizedDescription))"
        }
    }
}

protocol ShazamServiceDelegate: AnyObject {
    func shazamService(_ service: ShazamService, didChangeState state: RecognitionState)
}


class ShazamService: NSObject, ShazamServiceProtocol {
    weak var delegate: ShazamServiceDelegate?
    
    private let audioEngine = AVAudioEngine()
    private var session: SHSession?
    private var signatureGenerator: SHSignatureGenerator?
    
    private var currentState: RecognitionState = .idle {
        didSet {
            logWithTimestamp("State changed from \(oldValue) to \(currentState)")
            delegate?.shazamService(self, didChangeState: currentState)
        }
    }
    
    override init() {
        super.init()
        logSystemInfo()
        setupAudioSession()
    }
    
    private func logSystemInfo() {
        logWithTimestamp("ShazamKit System Info:")
        logWithTimestamp("  - iOS Version: \(ProcessInfo.processInfo.operatingSystemVersionString)")
        logWithTimestamp("  - Device: \(UIDevice.current.model)")
        logWithTimestamp("  - Simulator: \(isRunningInSimulator)")
        
        // Check if we're in a supported region/configuration
        let session = SHSession()
        logWithTimestamp("  - SHSession created successfully: \(session)")
    }
    
    private var isRunningInSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    deinit {
        stopListening()
    }
    
    // MARK: - Logging Helper
    
    private func logWithTimestamp(_ message: String) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        print("[\(timestamp)] ShazamService: \(message)")
    }
    
    // MARK: - ShazamServiceProtocol
    
    func startListening() async -> Result<SongMatch> {
        logWithTimestamp("startListening() called")
        do {
            logWithTimestamp("Requesting microphone permission...")
            try await requestMicrophonePermission()
            logWithTimestamp("Permission granted, starting recognition...")
            return await performRecognition()
        } catch {
            logWithTimestamp("Error in startListening: \(error)")
            let appError = error as? AppError ?? AppError.shazamError(.recognitionFailed(error.localizedDescription))
            currentState = .failure(appError)
            return .failure(appError)
        }
    }
    
    func stopListening() {
        logWithTimestamp("stopListening() called")
        
        // Remove any existing audio tap first
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.reset()
        
        session = nil
        signatureGenerator = nil
        currentState = .idle
        
        // Deactivate audio session to release input and allow other audio to resume
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
            logWithTimestamp("Audio session deactivated after listening")
        } catch {
            logWithTimestamp("Failed to deactivate audio session: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        logWithTimestamp("Setting up audio session...")
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            logWithTimestamp("Audio session setup successful")
        } catch {
            logWithTimestamp("Failed to setup audio session: \(error)")
        }
    }
    
    private func requestMicrophonePermission() async throws {
        logWithTimestamp("Checking microphone permission...")
        let permissionService = PermissionService()
        let status = try await permissionService.requestMicrophonePermission()
        logWithTimestamp("Permission status: \(status)")
        
        if status != .granted {
            logWithTimestamp("Permission denied, throwing error")
            throw AppError.shazamError(.noMicrophonePermission)
        }
    }
    
    // MARK: - Real ShazamKit Implementation
    
    private func performRecognition() async -> Result<SongMatch> {
        logWithTimestamp("Starting performRecognition()")
        return await withCheckedContinuation { continuation in
            do {
                logWithTimestamp("Setting state to listening...")
                currentState = .listening
                
                // Create signature generator
                logWithTimestamp("Creating signature generator...")
                signatureGenerator = SHSignatureGenerator()
                
                // Create and configure session
                logWithTimestamp("Creating and configuring SHSession...")
                session = SHSession()
                session?.delegate = self
                
                // Setup audio engine
                logWithTimestamp("Setting up audio engine...")
                let inputNode = audioEngine.inputNode
                let recordingFormat = inputNode.outputFormat(forBus: 0)
                logWithTimestamp("Recording format: \(recordingFormat)")
                
                // Remove any existing tap before installing a new one
                inputNode.removeTap(onBus: 0)
                
                audioBufferCount = 0
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                    guard let self = self,
                          let signatureGenerator = self.signatureGenerator else { return }
                    
                    self.audioBufferCount += 1
                    if self.audioBufferCount % 1000 == 0 {
                        self.logWithTimestamp("Audio buffers captured: \(self.audioBufferCount)")
                    }
                    
                    do {
                        try signatureGenerator.append(buffer, at: nil)
                    } catch {
                        // Handle specific ShazamKit signature errors
                        if error.localizedDescription.contains("Not a SigX Error") {
                            self.logWithTimestamp("Audio too quiet - increase volume or move closer to music source")
                        } else {
                            self.logWithTimestamp("Failed to append buffer: \(error)")
                        }
                    }
                }
                
                logWithTimestamp("Starting audio engine...")
                try audioEngine.start()
                logWithTimestamp("Audio engine started successfully")
                
                // Start recognition after a delay to collect enough audio
                let sampleDuration = AppSettings.shared.sampleDuration
                logWithTimestamp("Starting \(sampleDuration)-second audio capture...")
                Task { [weak self] in
                    let nanoseconds = UInt64(sampleDuration * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: nanoseconds)
                    guard let self = self else { return }
                    self.logWithTimestamp("\(sampleDuration) seconds elapsed, processing signature...")
                    await MainActor.run {
                        self.processSignature(continuation: continuation)
                    }
                }
                
            } catch {
                logWithTimestamp("Error in performRecognition: \(error)")
                let appError = AppError.shazamError(.audioSessionFailed)
                currentState = .failure(appError)
                continuation.resume(returning: .failure(appError))
            }
        }
    }
    
    private func processSignature(continuation: CheckedContinuation<Result<SongMatch>, Never>) {
        logWithTimestamp("processSignature() called")
        guard let signatureGenerator = signatureGenerator,
              let session = session else {
            logWithTimestamp("Missing signatureGenerator or session")
            let error = AppError.shazamError(.invalidSignature)
            currentState = .failure(error)
            continuation.resume(returning: .failure(error))
            return
        }
        
        logWithTimestamp("Setting state to processing...")
        currentState = .processing
        logWithTimestamp("Generating signature from captured audio...")
        let signature = signatureGenerator.signature()
        logWithTimestamp("Signature duration: \(signature.duration) seconds")
        logWithTimestamp("Total audio buffers captured: \(audioBufferCount)")
        logWithTimestamp("Signature details: \(signature)")
        logWithTimestamp("Signature data length: \(signature.dataRepresentation.count) bytes")
        logWithTimestamp("Signature created, starting match with Shazam catalog...")
        
        // Log session state before matching
        logWithTimestamp("Session state before match: \(String(describing: session))")
        logWithTimestamp("Signature properties - Duration: \(signature.duration)s, Data: \(signature.dataRepresentation.count) bytes")
        
        // Validate signature before sending to Shazam
        if signature.duration == 0 {
            logWithTimestamp("WARNING: Signature has zero duration")
            let error = AppError.shazamError(.recognitionFailed("No audio captured - ensure music is playing loudly enough"))
            currentState = .failure(error)
            continuation.resume(returning: .failure(error))
            return
        }
        if signature.dataRepresentation.isEmpty {
            logWithTimestamp("WARNING: Signature has no audio data")
            let error = AppError.shazamError(.recognitionFailed("Invalid audio signature - try increasing volume"))
            currentState = .failure(error)
            continuation.resume(returning: .failure(error))
            return
        }
        
        session.match(signature)
        logWithTimestamp("Match request sent to Shazam servers")
        logWithTimestamp("Waiting for SHSessionDelegate callbacks...")
        
        // Add a timeout mechanism
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 15_000_000_000) // 15 seconds timeout
            guard let self = self else { return }
            if case .processing = self.currentState {
                self.logWithTimestamp("Recognition timeout after 15 seconds - check network connectivity")
                let timeoutError = AppError.shazamError(.recognitionFailed("Network timeout - check internet connection"))
                self.currentState = .failure(timeoutError)
                self.recognitionContinuation?.resume(returning: .failure(timeoutError))
                self.recognitionContinuation = nil
                self.stopListening()
            }
        }
        
        // Store continuation for use in delegate methods
        self.recognitionContinuation = continuation
    }
    
    private var recognitionContinuation: CheckedContinuation<Result<SongMatch>, Never>?
    private var audioBufferCount = 0
}

// MARK: - SHSessionDelegate

extension ShazamService: SHSessionDelegate {
    func session(_ session: SHSession, didFind match: SHMatch) {
        logWithTimestamp("🎉 SHSessionDelegate: didFind match called!")
        logWithTimestamp("Match found! Processing result...")
        stopListening()
        
        guard let mediaItem = match.mediaItems.first else {
            logWithTimestamp("No media items in match")
            let error = AppError.shazamError(.noMatch)
            currentState = .failure(error)
            recognitionContinuation?.resume(returning: .failure(error))
            recognitionContinuation = nil
            return
        }
        
        // Parse metadata from ShazamKit response
        logWithTimestamp("Parsing song metadata...")
        let songMatch = parseSongMatch(from: mediaItem)
        logWithTimestamp("Successfully matched: \(songMatch.title) by \(songMatch.artist)")
        currentState = .success(songMatch)
        recognitionContinuation?.resume(returning: .success(songMatch))
        recognitionContinuation = nil
    }
    
    func session(_ session: SHSession, didNotFindMatchFor signature: SHSignature) {
        logWithTimestamp("❌ SHSessionDelegate: didNotFindMatchFor called")
        logWithTimestamp("No match found for signature")
        stopListening()
        
        let error = AppError.shazamError(.noMatch)
        currentState = .failure(error)
        recognitionContinuation?.resume(returning: .failure(error))
        recognitionContinuation = nil
    }
    
    func session(_ session: SHSession, didFailWithError error: Error) {
        logWithTimestamp("⚠️ SHSessionDelegate: didFailWithError called")
        logWithTimestamp("Recognition failed with error: \(error)")
        logWithTimestamp("Error type: \(type(of: error))")
        logWithTimestamp("Error domain: \(error.localizedDescription)")
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
        
        logWithTimestamp("Parsed metadata:")
        logWithTimestamp("  - Title: \(title)")
        logWithTimestamp("  - Artist: \(artist)")
        logWithTimestamp("  - Album: \(mediaItem.subtitle ?? "Unknown")")
        logWithTimestamp("  - Artwork URL: \(albumArtURL ?? "None")")
        logWithTimestamp("  - Apple Music ID: \(appleMusicID ?? "None")")
        logWithTimestamp("  - Shazam ID: \(shazamID ?? "None")")
        
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