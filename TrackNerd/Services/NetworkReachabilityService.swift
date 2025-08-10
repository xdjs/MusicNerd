import Foundation
import Network
import Combine

/// Network connection type
public enum NetworkConnectionType {
    case wifi
    case cellular
    case ethernet
    case other
    case unavailable
}

/// Network reachability status
public struct NetworkStatus {
    let isConnected: Bool
    let connectionType: NetworkConnectionType
    let isExpensive: Bool
    let isConstrained: Bool
    
    static let unavailable = NetworkStatus(
        isConnected: false,
        connectionType: .unavailable,
        isExpensive: false,
        isConstrained: false
    )
}

/// Service for monitoring network reachability using NWPathMonitor
public class NetworkReachabilityService: ObservableObject {
    static let shared = NetworkReachabilityService()
    
    @Published public private(set) var status = NetworkStatus.unavailable
    @Published public private(set) var isConnected = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "network.reachability", qos: .utility)
    private var isMonitoring = false
    
    private init() {
        setupMonitoring()
    }
    
    deinit {
        if isMonitoring {
            monitor.cancel()
        }
    }
    
    // MARK: - Public Methods
    
    /// Start monitoring network reachability
    public func startMonitoring() {
        guard !isMonitoring else {
            logWithTimestamp("Already monitoring network reachability")
            return
        }
        
        monitor.start(queue: queue)
        isMonitoring = true
        logWithTimestamp("Started network reachability monitoring")
    }
    
    /// Stop monitoring network reachability
    public func stopMonitoring() {
        guard isMonitoring else { return }
        
        monitor.cancel()
        isMonitoring = false
        logWithTimestamp("Stopped network reachability monitoring")
    }
    
    // MARK: - Private Methods
    
    private func setupMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.handlePathUpdate(path)
            }
        }
    }
    
    private func handlePathUpdate(_ path: NWPath) {
        let newStatus = createNetworkStatus(from: path)
        let wasConnected = status.isConnected
        let isNowConnected = newStatus.isConnected
        
        // Update published properties on main queue
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.status = newStatus
            self.isConnected = newStatus.isConnected
        }
        
        logNetworkStatusChange(from: wasConnected, to: isNowConnected, status: newStatus)
        
        // Post notification for other parts of the app
        NotificationCenter.default.post(
            name: .networkStatusChanged,
            object: newStatus
        )
    }
    
    private func createNetworkStatus(from path: NWPath) -> NetworkStatus {
        let isConnected = path.status == .satisfied
        let connectionType = determineConnectionType(from: path)
        let isExpensive = path.isExpensive
        let isConstrained = path.isConstrained
        
        return NetworkStatus(
            isConnected: isConnected,
            connectionType: connectionType,
            isExpensive: isExpensive,
            isConstrained: isConstrained
        )
    }
    
    private func determineConnectionType(from path: NWPath) -> NetworkConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else if path.status == .satisfied {
            return .other
        } else {
            return .unavailable
        }
    }
    
    private func logNetworkStatusChange(from wasConnected: Bool, to isNowConnected: Bool, status: NetworkStatus) {
        if wasConnected != isNowConnected {
            if isNowConnected {
                logWithTimestamp("Network connection established - \(status.connectionType)")
            } else {
                logWithTimestamp("Network connection lost")
            }
        } else if isNowConnected {
            logWithTimestamp("Network status updated - \(status.connectionType) (expensive: \(status.isExpensive), constrained: \(status.isConstrained))")
        }
    }
    
    private func logWithTimestamp(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())
        print("[\(timestamp)] NetworkReachability: \(message)")
    }
}

// MARK: - Extensions

extension NetworkConnectionType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .ethernet: return "Ethernet"
        case .other: return "Other"
        case .unavailable: return "Unavailable"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("NetworkStatusChanged")
}