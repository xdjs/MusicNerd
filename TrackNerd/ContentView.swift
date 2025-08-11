//
//  ContentView.swift
//  TrackNerd
//
//  Created by Carl Tydingco on 8/4/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .listen
    
    enum Tab: String, CaseIterable {
        case listen = "Listen"
        case history = "History"
        case settings = "Settings"
        
        var systemImage: String {
            switch self {
            case .listen:
                return "waveform"
            case .history:
                return "clock"
            case .settings:
                return "gear"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ListeningView(selectedTab: $selectedTab)
                .tabItem {
                    Label(Tab.listen.rawValue, systemImage: Tab.listen.systemImage)
                }
                .tag(Tab.listen)
                .accessibilityIdentifier("listen-tab")
            
            HistoryView()
                .tabItem {
                    Label(Tab.history.rawValue, systemImage: Tab.history.systemImage)
                }
                .tag(Tab.history)
                .accessibilityIdentifier("history-tab")
            
            SettingsView()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.systemImage)
                }
                .tag(Tab.settings)
                .accessibilityIdentifier("settings-tab")
        }
        .accentColor(Color.MusicNerd.primary)
    }
}

#Preview {
    ContentView()
}
