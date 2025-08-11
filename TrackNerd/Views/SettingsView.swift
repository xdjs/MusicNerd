//
//  SettingsView.swift
//  TrackNerd
//
//  Created by Carl Tydingco on 8/5/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var autoEnrichment = AppSettings.shared.autoEnrichment
    @State private var saveToAppleMusic = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showingSampleDurationPicker = false
    @State private var sampleDuration: TimeInterval = AppSettings.shared.sampleDuration
    @State private var showDebugInfo: Bool = AppSettings.shared.showDebugInfo
    @State private var showNetworkIndicator: Bool = AppSettings.shared.showNetworkIndicator
    @State private var useProductionServer: Bool = AppSettings.shared.useProductionServer
    @State private var showingCacheExpirationPicker = false
    @State private var cacheExpirationHours: Double = AppSettings.shared.cacheExpirationHours
    @State private var showingClearHistoryAlert = false
    
    private let settings = AppSettings.shared
    private let services = DefaultServiceContainer.shared
    
    var body: some View {
        NavigationView {
            List {
                // App Settings Section
                Section {
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(Color.MusicNerd.textSecondary)
                            .frame(width: 24)
                        
                        Text("Notifications")
                            .musicNerdStyle(.bodyLarge(color: Color.MusicNerd.textSecondary))
                        
                        Spacer()
                        
                        Toggle("", isOn: $notificationsEnabled)
                            .disabled(true)
                            .accessibilityIdentifier("notifications-toggle")
                    }
                    
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(Color.MusicNerd.textSecondary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto Enrichment")
                                .musicNerdStyle(.bodyLarge(color: Color.MusicNerd.textSecondary))
                            Text("Automatically get insights for recognized songs")
                                .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $autoEnrichment)
                            .accessibilityIdentifier("auto-enrichment-toggle")
                            .onChange(of: autoEnrichment) { _, newValue in
                                settings.autoEnrichment = newValue
                            }
                    }
                    
                    HStack {
                        Image(systemName: "music.note")
                            .foregroundColor(Color.MusicNerd.textSecondary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Save to Apple Music")
                                .musicNerdStyle(.bodyLarge(color: Color.MusicNerd.textSecondary))
                            Text("Add recognized songs to your Apple Music library")
                                .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $saveToAppleMusic)
                            .disabled(true)
                            .accessibilityIdentifier("apple-music-toggle")
                    }
                    
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(Color.MusicNerd.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sample Duration")
                                .musicNerdStyle(.bodyLarge())
                            Text("How long to listen before identifying")
                                .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
                        }
                        
                        Spacer()
                        
                        Button(AppSettings.formatDuration(sampleDuration)) {
                            showingSampleDurationPicker = true
                        }
                        .foregroundColor(Color.MusicNerd.primary)
                        .accessibilityIdentifier("sample-duration-button")
                    }
                } header: {
                    Text("Recognition")
                        .musicNerdStyle(.titleSmall(color: Color.MusicNerd.textSecondary))
                }
                
                // Cache Settings Section
                Section {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundColor(Color.MusicNerd.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cache Duration")
                                .musicNerdStyle(.bodyLarge())
                            Text("How long to store artist info locally")
                                .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
                        }
                        
                        Spacer()
                        
                        Button(AppSettings.formatCacheExpiration(cacheExpirationHours)) {
                            showingCacheExpirationPicker = true
                        }
                        .foregroundColor(Color.MusicNerd.primary)
                        .accessibilityIdentifier("cache-expiration-button")
                    }
                    
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        Text("Clear Cache")
                            .musicNerdStyle(.bodyLarge())
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Task { @MainActor in
                            EnrichmentCache.shared.clearAll()
                        }
                    }
                    .accessibilityIdentifier("clear-cache-button")
                } header: {
                    Text("Performance")
                        .musicNerdStyle(.titleSmall(color: Color.MusicNerd.textSecondary))
                }
                
                // Data & Privacy Section
                Section {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        Text("Clear History")
                            .musicNerdStyle(.bodyLarge())
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingClearHistoryAlert = true
                    }
                    .accessibilityIdentifier("clear-history-button")
                    
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color.MusicNerd.textSecondary)
                            .frame(width: 24)
                        
                        Text("Export Data")
                            .musicNerdStyle(.bodyLarge(color: Color.MusicNerd.textSecondary))
                    }
                    .accessibilityIdentifier("export-data-button")
                } header: {
                    Text("Data & Privacy")
                        .musicNerdStyle(.titleSmall(color: Color.MusicNerd.textSecondary))
                }
                
                // About Section
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color.MusicNerd.primary)
                            .frame(width: 24)
                        
                        Text("About TrackNerd")
                            .musicNerdStyle(.bodyLarge())
                        
                        Spacer()
                        
                        Text("1.0.0")
                            .musicNerdStyle(.bodyMedium(color: Color.MusicNerd.textSecondary))
                    }
                    .accessibilityIdentifier("about-button")
                    
                    HStack {
                        Image(systemName: "heart")
                            .foregroundColor(Color.MusicNerd.primary)
                            .frame(width: 24)
                        
                        Text("Rate TrackNerd")
                            .musicNerdStyle(.bodyLarge())
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        rateApp()
                    }
                    .accessibilityIdentifier("rate-app-button")
                    
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(Color.MusicNerd.primary)
                            .frame(width: 24)
                        
                        Text("Contact Support")
                            .musicNerdStyle(.bodyLarge())
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        contactSupport()
                    }
                    .accessibilityIdentifier("contact-support-button")
                    
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(Color.MusicNerd.primary)
                            .frame(width: 24)
                        
                        Text("Privacy Policy")
                            .musicNerdStyle(.bodyLarge())
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        openPrivacyPolicy()
                    }
                    .accessibilityIdentifier("privacy-policy-button")
                } header: {
                    Text("About")
                        .musicNerdStyle(.titleSmall(color: Color.MusicNerd.textSecondary))
                }
                
                // Debug Section
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color.MusicNerd.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Debug Info")
                                .musicNerdStyle(.bodyLarge())
                            Text("Display sample duration in main UI")
                                .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $showDebugInfo)
                            .accessibilityIdentifier("debug-info-toggle")
                            .onChange(of: showDebugInfo) { _, newValue in
                                settings.showDebugInfo = newValue
                            }
                    }
                    
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(Color.MusicNerd.textSecondary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Network Indicator")
                                .musicNerdStyle(.bodyLarge())
                            Text("Display network status indicator in main UI")
                                .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $showNetworkIndicator)
                            .accessibilityIdentifier("network-indicator-toggle")
                            .onChange(of: showNetworkIndicator) { _, newValue in
                                settings.showNetworkIndicator = newValue
                            }
                    }
                    
                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundColor(Color.MusicNerd.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Use Production Server")
                                .musicNerdStyle(.bodyLarge())
                            Text(useProductionServer ? "Using: api.musicnerd.xyz" : "Using: localhost:3000")
                                .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $useProductionServer)
                            .accessibilityIdentifier("production-server-toggle")
                            .onChange(of: useProductionServer) { _, newValue in
                                settings.useProductionServer = newValue
                            }
                    }
                    
                    HStack {
                        Image(systemName: "eye")
                            .foregroundColor(Color.MusicNerd.textSecondary)
                            .frame(width: 24)
                        
                        Text("Show Onboarding")
                            .musicNerdStyle(.bodyLarge(color: Color.MusicNerd.textSecondary))
                    }
                    .accessibilityIdentifier("show-onboarding-button")
                    
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color.MusicNerd.primary)
                            .frame(width: 24)
                        
                        Text("Reset Settings to Defaults")
                            .musicNerdStyle(.bodyLarge())
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        settings.resetToDefaults()
                        sampleDuration = AppSettings.shared.sampleDuration
                        showDebugInfo = AppSettings.shared.showDebugInfo
                        showNetworkIndicator = AppSettings.shared.showNetworkIndicator
                        useProductionServer = AppSettings.shared.useProductionServer
                        cacheExpirationHours = AppSettings.shared.cacheExpirationHours
                        autoEnrichment = AppSettings.shared.autoEnrichment
                    }
                    .accessibilityIdentifier("reset-settings-button")
                } header: {
                    Text("Debug")
                        .musicNerdStyle(.titleSmall(color: Color.MusicNerd.textSecondary))
                }
            }
            .listStyle(InsetGroupedListStyle())
            .background(Color.MusicNerd.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSampleDurationPicker) {
                SampleDurationPickerView(
                    selectedDuration: sampleDuration,
                    onSelection: { duration in
                        settings.sampleDuration = duration
                        sampleDuration = duration
                        showingSampleDurationPicker = false
                    }
                )
            }
            .sheet(isPresented: $showingCacheExpirationPicker) {
                CacheExpirationPickerView(
                    selectedHours: cacheExpirationHours,
                    onSelection: { hours in
                        settings.cacheExpirationHours = hours
                        cacheExpirationHours = hours
                        showingCacheExpirationPicker = false
                    }
                )
            }
            .alert("Clear All History", isPresented: $showingClearHistoryAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    Task {
                        await clearAllHistory()
                    }
                }
            } message: {
                Text("This will permanently delete all your recognized songs and history. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func clearAllHistory() async {
        let result = await services.storageService.loadMatches()
        switch result {
        case .success(let matches):
            // Delete all matches
            for match in matches {
                let _ = await services.storageService.delete(match)
            }
            
            // Clear cache as well
            EnrichmentCache.shared.clearAll()
        case .failure:
            // Even if loading fails, try to clear cache
            EnrichmentCache.shared.clearAll()
        }
    }
    
    
    private func rateApp() {
        // App Store URL for rating (would need actual App Store ID)
        let appStoreURL = "https://apps.apple.com/app/id1234567890"
        if let url = URL(string: appStoreURL) {
            UIApplication.shared.open(url)
        }
    }
    
    private func contactSupport() {
        let email = "support@musicnerd.xyz"
        let subject = "TrackNerd Support"
        let body = "Hello TrackNerd Team,\n\n"
        
        if let emailURL = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(emailURL)
        }
    }
    
    private func openPrivacyPolicy() {
        // Privacy policy URL (would need actual URL)
        let privacyURL = "https://musicnerd.xyz/privacy"
        if let url = URL(string: privacyURL) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SettingsView()
}