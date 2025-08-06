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
    
    private let settings = AppSettings.shared
    
    var body: some View {
        NavigationView {
            List {
                // App Settings Section
                Section {
                    HStack {
                        Image(systemName: "bell")
                            .foregroundColor(Color.MusicNerd.primary)
                            .frame(width: 24)
                        
                        Text("Notifications")
                            .musicNerdStyle(.bodyLarge())
                        
                        Spacer()
                        
                        Toggle("", isOn: $notificationsEnabled)
                            .accessibilityIdentifier("notifications-toggle")
                    }
                    
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(Color.MusicNerd.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto Enrichment")
                                .musicNerdStyle(.bodyLarge())
                            Text("Automatically get insights for recognized songs")
                                .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $autoEnrichment)
                            .accessibilityIdentifier("auto-enrichment-toggle")
                    }
                    
                    HStack {
                        Image(systemName: "music.note")
                            .foregroundColor(Color.MusicNerd.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Save to Apple Music")
                                .musicNerdStyle(.bodyLarge())
                            Text("Add recognized songs to your Apple Music library")
                                .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $saveToAppleMusic)
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
                        // TODO: Implement clear history
                    }
                    .accessibilityIdentifier("clear-history-button")
                    
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color.MusicNerd.primary)
                            .frame(width: 24)
                        
                        Text("Export Data")
                            .musicNerdStyle(.bodyLarge())
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // TODO: Implement export data
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
                        // TODO: Open App Store rating
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
                        // TODO: Open support email
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
                        // TODO: Open privacy policy
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
                            .foregroundColor(Color.MusicNerd.primary)
                            .frame(width: 24)
                        
                        Text("Show Onboarding")
                            .musicNerdStyle(.bodyLarge())
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hasSeenOnboarding = false
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
        }
    }
}

#Preview {
    SettingsView()
}