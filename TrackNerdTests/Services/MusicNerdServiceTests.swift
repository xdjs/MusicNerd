import XCTest
@testable import TrackNerd

final class MusicNerdServiceTests: XCTestCase {
    
    var musicNerdService: MusicNerdService!
    
    override func setUp() {
        super.setUp()
        musicNerdService = MusicNerdService()
    }
    
    override func tearDown() {
        musicNerdService = nil
        super.tearDown()
    }
    
    // MARK: - Search Artist Tests
    
    func testSearchArtist_WithValidName_ShouldReturnArtist() async throws {
        // This is an integration test that would require a real server
        // Skipping for now until we have mock capability or test server
        throw XCTSkip("Integration test requires live server connection")
    }
    
    func testSearchArtist_WithEmptyName_ShouldHandleGracefully() async {
        let result = await musicNerdService.searchArtist(name: "")
        
        switch result {
        case .success:
            XCTFail("Expected failure for empty search term")
        case .failure(let error):
            // Should handle empty search gracefully
            XCTAssertTrue(error is AppError)
        }
    }
    
    // MARK: - Get Artist Bio Tests
    
    func testGetArtistBio_WithValidId_ShouldReturnBio() async throws {
        // This is an integration test that would require a real server
        // Skipping for now until we have mock capability or test server
        throw XCTSkip("Integration test requires live server connection")
    }
    
    func testGetArtistBio_WithInvalidId_ShouldReturnError() async {
        let result = await musicNerdService.getArtistBio(artistId: "invalid")
        
        switch result {
        case .success:
            XCTFail("Expected failure for invalid artist ID")
        case .failure(let error):
            // Should handle invalid ID gracefully
            XCTAssertTrue(error is AppError)
        }
    }
    
    // MARK: - Get Fun Fact Tests
    
    func testGetFunFact_WithValidIdAndType_ShouldReturnFunFact() async throws {
        // This is an integration test that would require a real server
        // Skipping for now until we have mock capability or test server
        throw XCTSkip("Integration test requires live server connection")
    }
    
    func testGetFunFact_WithInvalidId_ShouldReturnError() async {
        let result = await musicNerdService.getFunFact(artistId: "invalid", type: .lore)
        
        switch result {
        case .success:
            XCTFail("Expected failure for invalid artist ID")
        case .failure(let error):
            // Should handle invalid ID gracefully
            XCTAssertTrue(error is AppError)
        }
    }
    
    // MARK: - Fun Fact Type Tests
    
    func testFunFactType_AllCases() {
        let allTypes = FunFactType.allCases
        
        XCTAssertEqual(allTypes.count, 4)
        XCTAssertTrue(allTypes.contains(.lore))
        XCTAssertTrue(allTypes.contains(.bts))
        XCTAssertTrue(allTypes.contains(.activity))
        XCTAssertTrue(allTypes.contains(.surprise))
    }
    
    func testFunFactType_RawValues() {
        XCTAssertEqual(FunFactType.lore.rawValue, "lore")
        XCTAssertEqual(FunFactType.bts.rawValue, "bts")
        XCTAssertEqual(FunFactType.activity.rawValue, "activity")
        XCTAssertEqual(FunFactType.surprise.rawValue, "surprise")
    }
    
    // MARK: - URL Construction Tests
    
    func testURLConstruction() {
        // Test that the service can construct URLs correctly
        let baseURL = AppConfiguration.API.baseURL
        let searchEndpoint = AppConfiguration.API.searchArtistsEndpoint
        let bioEndpoint = AppConfiguration.API.artistBioEndpoint
        let funFactsEndpoint = AppConfiguration.API.funFactsEndpoint
        
        // Verify endpoints are configured
        XCTAssertFalse(baseURL.isEmpty)
        XCTAssertTrue(searchEndpoint.hasPrefix("/"))
        XCTAssertTrue(bioEndpoint.hasPrefix("/"))
        XCTAssertTrue(funFactsEndpoint.hasPrefix("/"))
        
        // Test URL construction
        let searchURL = "\(baseURL)\(searchEndpoint)"
        let bioURL = "\(baseURL)\(bioEndpoint)/123"
        let funFactURL = "\(baseURL)\(funFactsEndpoint)/lore?id=123"
        
        XCTAssertNotNil(URL(string: searchURL))
        XCTAssertNotNil(URL(string: bioURL))
        XCTAssertNotNil(URL(string: funFactURL))
    }
}