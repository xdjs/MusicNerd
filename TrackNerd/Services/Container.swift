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
    func enrichSong(_ match: SongMatch) async -> Result<EnrichmentData> {
        fatalError("Not implemented")
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