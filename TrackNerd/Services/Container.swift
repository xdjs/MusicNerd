import Foundation
import SwiftData

@MainActor
final class Container: ObservableObject {
    static let shared = Container()
    
    lazy var modelContainer: ModelContainer = {
        let schema = Schema([
            SongMatch.self
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
}

@MainActor
final class DefaultServiceContainer: ServiceContainer {
    static let shared = DefaultServiceContainer()
    
    lazy var shazamService: ShazamServiceProtocol = ShazamService()
    lazy var openAIService: OpenAIServiceProtocol = OpenAIService()
    lazy var musicNerdService: MusicNerdServiceProtocol = MusicNerdService()
    lazy var storageService: StorageServiceProtocol = StorageService(
        modelContext: Container.shared.modelContainer.mainContext
    )
    lazy var permissionService: PermissionServiceProtocol = PermissionService()
    
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
            async let funFactResult = musicNerdService.getFunFact(artistId: artistId, type: .surprise)
            
            // Wait for both requests to complete
            let bio = await bioResult
            let funFact = await funFactResult
            
            // Step 3: Build enrichment data from results
            let artistBio = try? bio.get()
            let songFunFact = try? funFact.get()
            
            let enrichmentData = EnrichmentData(
                artistBio: artistBio,
                songTrivia: nil,
                funFact: songFunFact,
                relatedArtists: [],
                relatedSongs: [],
                genres: [],
                releaseYear: nil,
                albumName: match.album
            )
            
            logWithTimestamp("Enrichment completed - Bio: \(artistBio != nil ? "✓" : "✗"), Fun Fact: \(songFunFact != nil ? "✓" : "✗")")
            return .success(enrichmentData)
            
        case .failure(let error):
            logWithTimestamp("Artist not found in MusicNerd database: \(error.localizedDescription)")
            
            // Return minimal enrichment data when artist not found
            let enrichmentData = EnrichmentData(
                artistBio: nil,
                songTrivia: nil,
                funFact: nil,
                relatedArtists: [],
                relatedSongs: [],
                genres: [],
                releaseYear: nil,
                albumName: match.album
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