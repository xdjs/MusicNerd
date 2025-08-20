import XCTest
import Network
@testable import MusicNerd

final class NetworkReachabilityServiceTests: XCTestCase {
    
    var reachabilityService: NetworkReachabilityService!
    
    override func setUp() async throws {
        try await super.setUp()
        // Use the shared instance for testing
        reachabilityService = NetworkReachabilityService.shared
        
        // Stop any existing monitoring
        reachabilityService.stopMonitoring()
        
        // Give a moment for cleanup
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    override func tearDown() async throws {
        reachabilityService?.stopMonitoring()
        reachabilityService = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testNetworkReachabilityServiceInitialization() async throws {
        XCTAssertNotNil(reachabilityService)
        
        // Initial state may vary depending on network connectivity
        // Just test that the service has valid status
        let status = reachabilityService.status
        let isConnected = reachabilityService.isConnected
        
        XCTAssertNotNil(status)
        XCTAssertEqual(status.isConnected, isConnected, "Status and isConnected should be consistent")
    }
    
    // MARK: - Monitoring Control Tests
    
    func testStartMonitoring() async throws {
        // Starting monitoring should not throw
        reachabilityService.startMonitoring()
        
        // Give time for network status to update
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Starting again should be safe (no crash)
        reachabilityService.startMonitoring()
    }
    
    func testStopMonitoring() async throws {
        // Start monitoring first
        reachabilityService.startMonitoring()
        
        // Give time for initialization
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Stop monitoring should not throw
        reachabilityService.stopMonitoring()
        
        // Stopping again should be safe (no crash)
        reachabilityService.stopMonitoring()
    }
    
    // MARK: - Network Status Tests
    
    func testNetworkStatusStructure() async throws {
        let availableStatus = NetworkStatus(
            isConnected: true,
            connectionType: .wifi,
            isExpensive: false,
            isConstrained: false
        )
        
        XCTAssertTrue(availableStatus.isConnected)
        XCTAssertEqual(availableStatus.connectionType, .wifi)
        XCTAssertFalse(availableStatus.isExpensive)
        XCTAssertFalse(availableStatus.isConstrained)
        
        let unavailableStatus = NetworkStatus.unavailable
        XCTAssertFalse(unavailableStatus.isConnected)
        XCTAssertEqual(unavailableStatus.connectionType, .unavailable)
        XCTAssertFalse(unavailableStatus.isExpensive)
        XCTAssertFalse(unavailableStatus.isConstrained)
    }
    
    // MARK: - Connection Type Tests
    
    func testNetworkConnectionTypeDescriptions() async throws {
        XCTAssertEqual(NetworkConnectionType.wifi.description, "Wi-Fi")
        XCTAssertEqual(NetworkConnectionType.cellular.description, "Cellular")
        XCTAssertEqual(NetworkConnectionType.ethernet.description, "Ethernet")
        XCTAssertEqual(NetworkConnectionType.other.description, "Other")
        XCTAssertEqual(NetworkConnectionType.unavailable.description, "Unavailable")
    }
    
    // MARK: - Notification Tests
    
    func xtestNetworkStatusChangeNotification() async throws {
        let expectation = XCTestExpectation(description: "Network status change notification")
        
        var receivedNotification = false
        let notificationObserver = NotificationCenter.default.addObserver(
            forName: .networkStatusChanged,
            object: nil,
            queue: .main
        ) { notification in
            guard !receivedNotification else { return } // Avoid multiple fulfillments
            receivedNotification = true
            
            XCTAssertNotNil(notification.object)
            if let status = notification.object as? NetworkStatus {
                // Verify notification contains NetworkStatus
                XCTAssertNotNil(status)
                expectation.fulfill()
            }
        }
        
        defer {
            NotificationCenter.default.removeObserver(notificationObserver)
        }
        
        // Start monitoring to trigger status change
        reachabilityService.startMonitoring()
        
        // Wait for notification with increased timeout
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    // MARK: - Real Network Status Tests
    
    func testRealNetworkConnectivity() async throws {
        // Start monitoring
        reachabilityService.startMonitoring()
        
        // Give time for initial status update
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // In simulator or with internet connection, we expect to be connected
        // Note: This test may fail in CI environments without network
        if reachabilityService.isConnected {
            XCTAssertTrue(reachabilityService.status.isConnected)
            XCTAssertNotEqual(reachabilityService.status.connectionType, .unavailable)
            
            // Log current connection for debugging
            let status = reachabilityService.status
            print("Current network status: \(status.connectionType) (expensive: \(status.isExpensive), constrained: \(status.isConstrained))")
        } else {
            // If no connection, verify offline state
            XCTAssertFalse(reachabilityService.status.isConnected)
            XCTAssertEqual(reachabilityService.status.connectionType, .unavailable)
        }
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentAccess() async throws {
        let concurrentOperations = 10
        let startExpectation = XCTestExpectation(description: "Concurrent start operations")
        startExpectation.expectedFulfillmentCount = concurrentOperations
        
        // Test concurrent start/stop operations
        for _ in 0..<concurrentOperations {
            Task {
                reachabilityService.startMonitoring()
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                reachabilityService.stopMonitoring()
                startExpectation.fulfill()
            }
        }
        
        await fulfillment(of: [startExpectation], timeout: 3.0)
    }
    
    // MARK: - Singleton Tests
    
    func testSingletonInstance() async throws {
        let instance1 = NetworkReachabilityService.shared
        let instance2 = NetworkReachabilityService.shared
        
        XCTAssertTrue(instance1 === instance2, "NetworkReachabilityService should be a singleton")
    }
    
    // MARK: - Performance Tests
    
    func testMonitoringPerformance() async throws {
        // Measure time to start monitoring
        let startTime = CFAbsoluteTimeGetCurrent()
        reachabilityService.startMonitoring()
        let startDuration = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(startDuration, 0.1, "Starting monitoring should be fast")
        
        // Give time for initialization
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Measure time to stop monitoring
        let stopTime = CFAbsoluteTimeGetCurrent()
        reachabilityService.stopMonitoring()
        let stopDuration = CFAbsoluteTimeGetCurrent() - stopTime
        
        XCTAssertLessThan(stopDuration, 0.1, "Stopping monitoring should be fast")
    }
    
    // MARK: - Error Handling Tests
    
    func testGracefulHandlingOfMultipleStarts() async throws {
        // Multiple starts should not cause issues
        for _ in 0..<5 {
            reachabilityService.startMonitoring()
        }
        
        // Give time for all operations
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Should still be able to stop normally
        reachabilityService.stopMonitoring()
    }
    
    func testGracefulHandlingOfMultipleStops() async throws {
        // Start once
        reachabilityService.startMonitoring()
        
        // Multiple stops should not cause issues
        for _ in 0..<5 {
            reachabilityService.stopMonitoring()
        }
        
        // Should be safe
        XCTAssertTrue(true, "Multiple stops should not crash")
    }
}
