//
//  SettingsView.swift
//  TrackNerd
//
//  Created by Carl Tydingco on 8/5/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var autoEnrichment = true
    @State private var saveToAppleMusic = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showingSampleDurationPicker = false
    @State private var sampleDuration: TimeInterval = AppSettings.shared.sampleDuration
    @State private var showDebugInfo: Bool = AppSettings.shared.showDebugInfo
    @State private var useProductionServer: Bool = AppSettings.shared.useProductionServer
    @State private var showingCacheExpirationPicker = false
    @State private var cacheExpirationHours: Double = AppSettings.shared.cacheExpirationHours
    
    private let settings = AppSettings.shared
    
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
                            .disabled(true)
                            .accessibilityIdentifier("auto-enrichment-toggle")
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
                        EnrichmentCache.shared.clearAll()
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
                            .foregroundColor(Color.MusicNerd.textSecondary)
                            .frame(width: 24)
                        
                        Text("Clear History")
                            .musicNerdStyle(.bodyLarge(color: Color.MusicNerd.textSecondary))
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
                            .foregroundColor(Color.MusicNerd.textSecondary)
                            .frame(width: 24)
                        
                        Text("Rate TrackNerd")
                            .musicNerdStyle(.bodyLarge(color: Color.MusicNerd.textSecondary))
                    }
                    .accessibilityIdentifier("rate-app-button")
                    
                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(Color.MusicNerd.textSecondary)
                            .frame(width: 24)
                        
                        Text("Contact Support")
                            .musicNerdStyle(.bodyLarge(color: Color.MusicNerd.textSecondary))
                    }
                    .accessibilityIdentifier("contact-support-button")
                    
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(Color.MusicNerd.textSecondary)
                            .frame(width: 24)
                        
                        Text("Privacy Policy")
                            .musicNerdStyle(.bodyLarge(color: Color.MusicNerd.textSecondary))
                    }
                    .accessibilityIdentifier("privacy-policy-button")
                } header: {
                    Text("About")
                        .musicNerdStyle(.titleSmall(color: Color.MusicNerd.textSecondary))
                }
                
                // Debug Section (only in debug builds)
                #if DEBUG
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
                        useProductionServer = AppSettings.shared.useProductionServer
                        cacheExpirationHours = AppSettings.shared.cacheExpirationHours
                    }
                    .accessibilityIdentifier("reset-settings-button")
                } header: {
                    Text("Debug")
                        .musicNerdStyle(.titleSmall(color: Color.MusicNerd.textSecondary))
                }
                #endif
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
        }
    }
}

#Preview {
    SettingsView()
}