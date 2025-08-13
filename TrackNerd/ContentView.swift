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
                .withMiniPlayer()
                .tabItem {
                    Label(Tab.listen.rawValue, systemImage: Tab.listen.systemImage)
                }
                .tag(Tab.listen)
                .accessibilityIdentifier("listen-tab")
            
            HistoryView()
                .withMiniPlayer()
                .tabItem {
                    Label(Tab.history.rawValue, systemImage: Tab.history.systemImage)
                }
                .tag(Tab.history)
                .accessibilityIdentifier("history-tab")
            
            SettingsView()
                .withMiniPlayer()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.systemImage)
                }
                .tag(Tab.settings)
                .accessibilityIdentifier("settings-tab")
        }
        .accentColor(Color.MusicNerd.primary)
    }
}

private struct MiniPlayerInset: View {
    @EnvironmentObject private var appleMusic: AppleMusicService
    @EnvironmentObject private var services: DefaultServiceContainer
    @State private var isShowingDetail: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            MiniPlayerView {
                isShowingDetail = true
            }
            .padding(.horizontal, CGFloat.MusicNerd.screenMargin)
            .padding(.bottom, 4)
        }
        .sheet(isPresented: $isShowingDetail) {
            if let match = appleMusic.currentMatch {
                MatchDetailView(match: match)
                    .environmentObject(services)
                    .environmentObject(appleMusic)
            }
        }
        .background(Color.clear)
    }
}

private struct MiniPlayerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom) {
            MiniPlayerInset()
        }
    }
}

private extension View {
    func withMiniPlayer() -> some View {
        modifier(MiniPlayerModifier())
    }
}

#Preview {
    ContentView()
}
