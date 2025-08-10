//
//  TrackNerdApp.swift
//  TrackNerd
//
//  Created by Carl Tydingco on 8/4/25.
//

import SwiftUI

@main
struct TrackNerdApp: App {
    
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
        }
    }
}
