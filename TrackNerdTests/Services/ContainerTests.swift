import XCTest
import SwiftData
@testable import TrackNerd

final class ContainerTests: XCTestCase {
    
    @MainActor
    func testContainerSingleton() {
        let container1 = Container.shared
        let container2 = Container.shared
        
        XCTAssertTrue(container1 === container2)
    }
    
    @MainActor
    func testModelContainerCreation() {
        let container = Container.shared
        let modelContainer = container.modelContainer
        
        XCTAssertNotNil(modelContainer)
        XCTAssertNotNil(modelContainer.mainContext)
    }
    
    @MainActor func testServiceContainerSingleton() {
        let container1 = DefaultServiceContainer.shared
        let container2 = DefaultServiceContainer.shared
        
        XCTAssertTrue(container1 === container2)
    }
    
    @MainActor
    func testServiceContainerServices() {
        let container = DefaultServiceContainer.shared
        
        XCTAssertNotNil(container.shazamService)
        XCTAssertNotNil(container.openAIService)
        XCTAssertNotNil(container.storageService)
        
        XCTAssertTrue(container.shazamService is ShazamService)
        XCTAssertTrue(container.openAIService is OpenAIService)
        XCTAssertTrue(container.storageService is StorageService)
    }
    
    @MainActor
    func testServiceLazyInitialization() {
        let container = DefaultServiceContainer.shared
        
        let shazamService1 = container.shazamService
        let shazamService2 = container.shazamService
        
        XCTAssertTrue(shazamService1 === shazamService2)
    }
    
    @MainActor
    func testStorageServiceWithMockContext() async {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema = Schema([SongMatch.self])
        
        do {
            let modelContainer = try ModelContainer(for: schema, configurations: [config])
            let context = modelContainer.mainContext
            let storageService = StorageService(modelContext: context)
            
            let testMatch = SongMatch(title: "Test Song", artist: "Test Artist")
            
            let saveResult = await storageService.save(testMatch)
            switch saveResult {
            case .success:
                let loadResult = await storageService.loadMatches()
                switch loadResult {
                case .success(let matches):
                    XCTAssertEqual(matches.count, 1)
                    XCTAssertEqual(matches.first?.title, "Test Song")
                case .failure:
                    XCTFail("Failed to load matches")
                }
            case .failure:
                XCTFail("Failed to save match")
            }
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }
    }
    
    @MainActor
    func testStorageServiceDelete() async {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let schema = Schema([SongMatch.self])
        
        do {
            let modelContainer = try ModelContainer(for: schema, configurations: [config])
            let context = modelContainer.mainContext
            let storageService = StorageService(modelContext: context)
            
            let testMatch = SongMatch(title: "Test Song", artist: "Test Artist")
            
            _ = await storageService.save(testMatch)
            
            let deleteResult = await storageService.delete(testMatch)
            switch deleteResult {
            case .success:
                let loadResult = await storageService.loadMatches()
                switch loadResult {
                case .success(let matches):
                    XCTAssertEqual(matches.count, 0)
                case .failure:
                    XCTFail("Failed to load matches after delete")
                }
            case .failure:
                XCTFail("Failed to delete match")
            }
        } catch {
            XCTFail("Failed to create model container: \(error)")
        }
    }
}
