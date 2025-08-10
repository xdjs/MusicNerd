import SwiftUI

struct NetworkStatusIndicator: View {
    @StateObject private var reachabilityService = NetworkReachabilityService.shared
    @State private var showDetails = false
    @AppStorage("show_network_indicator") private var showNetworkIndicator = false
    
    var body: some View {
        // Show if debug setting is enabled OR if running UI tests
        if showNetworkIndicator || ProcessInfo.processInfo.arguments.contains("--uitesting") {
            networkIndicatorContent
        }
    }
    
    private var networkIndicatorContent: some View {
        HStack(spacing: 8) {
            if reachabilityService.isConnected {
                connectedIndicator
            } else {
                disconnectedIndicator
            }
            
            if showDetails {
                Text(connectionStatusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showDetails.toggle()
            }
        }
        .accessibilityIdentifier("networkStatusIndicator")
        .accessibilityLabel("Network status: \(connectionStatusText)")
    }
    
    private var connectedIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(connectionColor)
                .frame(width: 8, height: 8)
            
            if showDetails {
                Image(systemName: connectionIcon)
                    .font(.caption)
                    .foregroundColor(connectionColor)
            }
        }
    }
    
    private var disconnectedIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
            
            if showDetails {
                Image(systemName: "wifi.slash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var connectionColor: Color {
        switch reachabilityService.status.connectionType {
        case .wifi:
            return .green
        case .cellular:
            return reachabilityService.status.isExpensive ? .orange : .blue
        case .ethernet:
            return .green
        case .other:
            return .blue
        case .unavailable:
            return .red
        }
    }
    
    private var connectionIcon: String {
        switch reachabilityService.status.connectionType {
        case .wifi:
            return "wifi"
        case .cellular:
            return "antenna.radiowaves.left.and.right"
        case .ethernet:
            return "cable.connector"
        case .other:
            return "network"
        case .unavailable:
            return "wifi.slash"
        }
    }
    
    private var connectionStatusText: String {
        if reachabilityService.isConnected {
            let type = reachabilityService.status.connectionType.description
            let qualifiers = [
                reachabilityService.status.isExpensive ? "expensive" : nil,
                reachabilityService.status.isConstrained ? "constrained" : nil
            ].compactMap { $0 }
            
            if qualifiers.isEmpty {
                return type
            } else {
                return "\(type) (\(qualifiers.joined(separator: ", ")))"
            }
        } else {
            return "Offline"
        }
    }
}

// MARK: - Previews

struct NetworkStatusIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            NetworkStatusIndicator()
            
            Text("Tap the indicator to toggle details")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}