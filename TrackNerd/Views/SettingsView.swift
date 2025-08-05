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
        }
    }
}

#Preview {
    SettingsView()
}