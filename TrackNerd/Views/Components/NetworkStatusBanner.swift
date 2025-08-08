import SwiftUI

struct NetworkStatusBanner: View {
    @StateObject private var reachabilityService = NetworkReachabilityService.shared
    
    var body: some View {
        Group {
            if !reachabilityService.isConnected {
                offlineBanner
            }
        }
        .animation(.easeInOut(duration: 0.3), value: reachabilityService.isConnected)
    }
    
    private var offlineBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.title3)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("No Internet Connection")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                
                Text("Music recognition requires internet access")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, CGFloat.MusicNerd.md)
        .padding(.vertical, CGFloat.MusicNerd.sm)
        .background(
            RoundedRectangle(cornerRadius: CGFloat.BorderRadius.md)
                .fill(Color.red.gradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CGFloat.BorderRadius.md)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, CGFloat.MusicNerd.md)
        .accessibilityIdentifier("networkStatusBanner")
        .accessibilityLabel("No internet connection. Music recognition requires internet access.")
    }
}

// MARK: - Previews

struct NetworkStatusBanner_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            NetworkStatusBanner()
            
            Text("Banner only shows when offline")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}