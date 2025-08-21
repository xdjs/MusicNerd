//
//  MusicNerdApp.swift
//  MusicNerd
//
//  Created by Carl Tydingco on 8/4/25.
//

import SwiftUI
import SwiftData

@main
struct MusicNerdApp: App {
    
    init() {
        // Disable animations during UI testing for faster and more reliable tests
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            UIView.setAnimationsEnabled(false)
        }
        
        // Start network reachability monitoring
        NetworkReachabilityService.shared.startMonitoring()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(DefaultServiceContainer.shared)
                .environmentObject(DefaultServiceContainer.shared.appleMusicServiceObject)
        }
        .modelContainer(for: [SongMatch.self, EnrichmentData.self, EnrichmentCacheEntry.self])
    }
}
