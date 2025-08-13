import Foundation
import SwiftData
import Combine

@MainActor
final class Container: ObservableObject {
    static let shared = Container()
    
    lazy var modelContainer: ModelContainer = {
        let schema = Schema([
            SongMatch.self,
            EnrichmentData.self,
            EnrichmentCacheEntry.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    private init() {}
}

protocol ServiceContainer {
    var shazamService: ShazamServiceProtocol { get }
    var openAIService: OpenAIServiceProtocol { get }
    var musicNerdService: MusicNerdServiceProtocol { get }
    var storageService: StorageServiceProtocol { get }
    var permissionService: PermissionServiceProtocol { get }
    var appleMusicService: AppleMusicServiceProtocol { get }
}

@MainActor
final class DefaultServiceContainer: ServiceContainer, ObservableObject {
    static let shared = DefaultServiceContainer()
    
    lazy var shazamService: ShazamServiceProtocol = ShazamService()
    lazy var openAIService: OpenAIServiceProtocol = OpenAIService()
    lazy var musicNerdService: MusicNerdServiceProtocol = MusicNerdService()
    lazy var storageService: StorageServiceProtocol = StorageService(
        modelContext: Container.shared.modelContainer.mainContext
    )
    lazy var permissionService: PermissionServiceProtocol = PermissionService()
    // Store a concrete instance for SwiftUI environment injection
    private lazy var _appleMusicServiceObject = AppleMusicService()
    // Expose protocol-typed service for general use
    lazy var appleMusicService: AppleMusicServiceProtocol = _appleMusicServiceObject
    // Expose concrete type for EnvironmentObject injection
    var appleMusicServiceObject: AppleMusicService { _appleMusicServiceObject }
    
    private init() {}
}

protocol ShazamServiceProtocol: AnyObject {
    func startListening() async -> Result<SongMatch>
    func stopListening()
}

protocol OpenAIServiceProtocol: AnyObject {
    func enrichSong(_ match: SongMatch) async -> Result<EnrichmentData>
}

protocol StorageServiceProtocol: AnyObject {
    func save(_ match: SongMatch) async -> Result<Void>
    func loadMatches() async -> Result<[SongMatch]>
    func delete(_ match: SongMatch) async -> Result<Void>
}


class OpenAIService: OpenAIServiceProtocol {
    private let musicNerdService: MusicNerdServiceProtocol
    
    init(musicNerdService: MusicNerdServiceProtocol = MusicNerdService()) {
        self.musicNerdService = musicNerdService
    }
    
    func enrichSong(_ match: SongMatch) async -> Result<EnrichmentData> {
        logWithTimestamp("Starting enrichment for: '\(match.title)' by '\(match.artist)'")
        
        // Step 1: Search for artist in MusicNerd database
        let searchResult = await musicNerdService.searchArtist(name: match.artist)
        
        switch searchResult {
        case .success(let musicNerdArtist):
            guard let artistId = musicNerdArtist.artistId else {
                logWithTimestamp("Found artist '\(musicNerdArtist.name)' but no valid ID")
                return .failure(.musicNerdError(.artistNotFound))
            }
            
            logWithTimestamp("Found MusicNerd artist: '\(musicNerdArtist.name)' (ID: \(artistId))")
            
            // Step 2: Get enrichment data concurrently
            async let bioResult = musicNerdService.getArtistBio(artistId: artistId)
            async let loreFunFactResult = musicNerdService.getFunFact(artistId: artistId, type: .lore)
            async let btsFunFactResult = musicNerdService.getFunFact(artistId: artistId, type: .bts)
            async let activityFunFactResult = musicNerdService.getFunFact(artistId: artistId, type: .activity)
            async let surpriseFunFactResult = musicNerdService.getFunFact(artistId: artistId, type: .surprise)
            
            // Wait for all requests to complete
            let bio = await bioResult
            let loreFunFact = await loreFunFactResult
            let btsFunFact = await btsFunFactResult
            let activityFunFact = await activityFunFactResult
            let surpriseFunFact = await surpriseFunFactResult
            
            // Step 3: Build enrichment data from results with error tracking
            let artistBio = try? bio.get()
            let legacySongFunFact = try? surpriseFunFact.get() // Keep first surprise fun fact for legacy compatibility
            
            // Track bio error
            let bioError: EnrichmentError? = {
                if case .failure(let error) = bio {
                    return EnrichmentError.from(error)
                }
                return nil
            }()
            
            // Build categorized fun facts dictionary and track errors
            var categorizedFunFacts: [String: String] = [:]
            var funFactErrors: [String: EnrichmentError] = [:]
            
            // Process lore fact
            if let lore = try? loreFunFact.get() {
                categorizedFunFacts["lore"] = lore
                logWithTimestamp("✓ Lore fact retrieved: \(lore.prefix(50))...")
            } else {
                if case .failure(let error) = loreFunFact {
                    funFactErrors["lore"] = EnrichmentError.from(error)
                }
                logWithTimestamp("✗ Lore fact failed or empty")
            }
            
            // Process BTS fact
            if let bts = try? btsFunFact.get() {
                categorizedFunFacts["bts"] = bts
                logWithTimestamp("✓ BTS fact retrieved: \(bts.prefix(50))...")
            } else {
                if case .failure(let error) = btsFunFact {
                    funFactErrors["bts"] = EnrichmentError.from(error)
                }
                logWithTimestamp("✗ BTS fact failed or empty")
            }
            
            // Process activity fact
            if let activity = try? activityFunFact.get() {
                categorizedFunFacts["activity"] = activity
                logWithTimestamp("✓ Activity fact retrieved: \(activity.prefix(50))...")
            } else {
                if case .failure(let error) = activityFunFact {
                    funFactErrors["activity"] = EnrichmentError.from(error)
                }
                logWithTimestamp("✗ Activity fact failed or empty")
            }
            
            // Process surprise fact
            if let surprise = try? surpriseFunFact.get() {
                categorizedFunFacts["surprise"] = surprise
                logWithTimestamp("✓ Surprise fact retrieved: \(surprise.prefix(50))...")
            } else {
                if case .failure(let error) = surpriseFunFact {
                    funFactErrors["surprise"] = EnrichmentError.from(error)
                }
                logWithTimestamp("✗ Surprise fact failed or empty")
            }
            
            let enrichmentData = EnrichmentData(
                artistBio: artistBio,
                songTrivia: nil,
                funFact: legacySongFunFact,
                funFacts: categorizedFunFacts,
                relatedArtists: [],
                relatedSongs: [],
                genres: [],
                releaseYear: nil,
                albumName: match.album,
                musicNerdArtistId: artistId,
                bioError: bioError,
                funFactErrors: funFactErrors
            )
            
            logWithTimestamp("Enrichment completed - Bio: \(artistBio != nil ? "✓" : "✗"), Fun Facts: \(categorizedFunFacts.count) types (\(categorizedFunFacts.keys.sorted().joined(separator: ", ")))")
            return .success(enrichmentData)
            
        case .failure(let error):
            logWithTimestamp("Artist not found in MusicNerd database: \(error.localizedDescription)")
            
            // Return enrichment data with error information
            let enrichmentError = EnrichmentError.from(error)
            let enrichmentData = EnrichmentData(
                artistBio: nil,
                songTrivia: nil,
                funFact: nil,
                funFacts: [:],
                relatedArtists: [],
                relatedSongs: [],
                genres: [],
                releaseYear: nil,
                albumName: match.album,
                bioError: enrichmentError,
                funFactErrors: [
                    "lore": enrichmentError,
                    "bts": enrichmentError,
                    "activity": enrichmentError,
                    "surprise": enrichmentError
                ]
            )
            
            return .success(enrichmentData)
        }
    }
    
    // MARK: - Logging Helper
    
    private func logWithTimestamp(_ message: String) {
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        print("[\(timestamp)] OpenAIService: \(message)")
    }
}

class StorageService: StorageServiceProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func save(_ match: SongMatch) async -> Result<Void> {
        do {
            modelContext.insert(match)
            try modelContext.save()
            return .success(())
        } catch {
            return .failure(.storageError(.saveFailed))
        }
    }
    
    func loadMatches() async -> Result<[SongMatch]> {
        do {
            let descriptor = FetchDescriptor<SongMatch>(
                sortBy: [SortDescriptor(\.matchedAt, order: .reverse)]
            )
            let matches = try modelContext.fetch(descriptor)
            return .success(matches)
        } catch {
            return .failure(.storageError(.loadFailed))
        }
    }
    
    func delete(_ match: SongMatch) async -> Result<Void> {
        do {
            modelContext.delete(match)
            try modelContext.save()
            return .success(())
        } catch {
            return .failure(.storageError(.deleteFailed))
        }
    }
}