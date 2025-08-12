//
//  MatchDetailView.swift
//  TrackNerd
//
//  Created by Carl Tydingco on 8/7/25.
//

import SwiftUI
import UIKit
import MusicKit

struct MatchDetailView: View {
    let match: SongMatch
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var isRetrying = false
    @State private var retryCount = 0
    @EnvironmentObject private var services: DefaultServiceContainer
    @EnvironmentObject private var appleMusic: AppleMusicService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: CGFloat.MusicNerd.lg) {
                    headerSection
                    playbackControls
                    contentSection
                    Spacer(minLength: CGFloat.MusicNerd.xl)
                }
                .padding(CGFloat.MusicNerd.screenMargin)
            }
            .background(Color.MusicNerd.background)
            .navigationTitle("Track Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color.MusicNerd.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color.MusicNerd.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
        .alert("Apple Music Access Needed", isPresented: $showAuthDeniedAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Please allow Apple Music access to play previews.")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: CGFloat.MusicNerd.md) {
            AlbumArtworkView(url: match.albumArtURL, size: 200)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            trackInfoSection
        }
        .padding(.top, CGFloat.MusicNerd.lg)
    }
    
    private var trackInfoSection: some View {
        VStack(spacing: CGFloat.MusicNerd.xs) {
            Text(match.title)
                .musicNerdStyle(.displayMedium())
                .multilineTextAlignment(.center)
            
            Text(match.artist)
                .musicNerdStyle(.headlineMedium(color: Color.MusicNerd.textSecondary))
                .multilineTextAlignment(.center)
            
            if let album = match.album {
                Text(album)
                    .musicNerdStyle(.bodyMedium(color: Color.MusicNerd.textSecondary))
                    .multilineTextAlignment(.center)
            }
            
            Text("Matched \(match.formattedMatchDate)")
                .musicNerdStyle(.caption(color: Color.MusicNerd.textSecondary))
        }
    }
    
    private var contentSection: some View {
        Group {
            if let enrichmentData = match.enrichmentData {
                enrichmentSections(enrichmentData)
            } else {
                loadingSection
            }
        }
    }

    private var playbackControls: some View {
        VStack(spacing: CGFloat.MusicNerd.sm) {
            HStack(spacing: CGFloat.MusicNerd.sm) {
                MusicNerdButton(
                    title: appleMusic.isPlayingPreview ? "Pause" : "Play Preview",
                    action: {
                        if appleMusic.isPlayingPreview {
                            services.appleMusicService.pause()
                        } else {
                            Task { await playPreview() }
                        }
                    },
                    style: .primary,
                    size: .medium,
                    isEnabled: !isResolvingPreview && isPreviewAvailable,
                    isLoading: isResolvingPreview
                )
                
                // Removed Resume button (not needed)
            }
            .padding(.top, CGFloat.MusicNerd.sm)

            // Progress + status
            VStack(spacing: CGFloat.MusicNerd.xs) {
                ProgressView(value: appleMusic.previewProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color.MusicNerd.primary))
                    .opacity(appleMusic.isPlayingPreview || appleMusic.previewProgress > 0 ? 1 : 0)
                if !isPreviewAvailable {
                    Text("Preview not available for this track")
                        .musicNerdStyle(.caption(color: Color.MusicNerd.textSecondary))
                }
            }
        }
    }

    @State private var isResolvingPreview: Bool = false
    @State private var isPreviewAvailable: Bool = true
    @State private var showAuthDeniedAlert: Bool = false

    private func playPreview() async {
        // 1) Authorize
        let status = await services.appleMusicService.requestAuthorization()
        guard status == .authorized else {
            await MainActor.run { showAuthDeniedAlert = true }
            return
        }
        
        // 2) Resolve song via appleMusicID or search
        await MainActor.run { isResolvingPreview = true }
        var song: Song?
        if let id = match.appleMusicID {
            song = await services.appleMusicService.song(fromAppleMusicID: id)
        }
        if song == nil {
            song = await services.appleMusicService.searchSong(title: match.title, artist: match.artist)
        }
        guard let resolved = song, let url = services.appleMusicService.previewURL(for: resolved) else {
            await MainActor.run {
                isResolvingPreview = false
                isPreviewAvailable = false
            }
            return
        }
        
        // 3) Play preview
        services.appleMusicService.playPreview(url: url)
        await MainActor.run { isResolvingPreview = false; isPreviewAvailable = true }
    }
    
    private func enrichmentSections(_ enrichmentData: EnrichmentData) -> some View {
        LazyVStack(spacing: CGFloat.MusicNerd.lg) {
            // Artist Bio Section (with fallback)
            if let bio = enrichmentData.artistBio, !bio.isEmpty {
                EnrichmentSectionView(
                    title: "About \(match.artist)",
                    content: bio,
                    icon: "person.circle"
                )
            } else if let bioError = enrichmentData.bioError {
                FallbackSectionView(
                    title: "About \(match.artist)",
                    errorMessage: bioError.fallbackMessage,
                    icon: "person.circle",
                    isRetryable: bioError.isRetryable,
                    isRetrying: isRetrying,
                    onRetry: { retryEnrichment() }
                )
            }
            
            // Display categorized fun facts (with fallbacks)
            if !enrichmentData.funFacts.isEmpty || !enrichmentData.funFactErrors.isEmpty {
                funFactSectionsWithFallbacks(enrichmentData.funFacts, errors: enrichmentData.funFactErrors)
            } else if let funFact = enrichmentData.funFact, !funFact.isEmpty {
                // Fallback for legacy single fun fact
                EnrichmentSectionView(
                    title: "Music Nerd Insight",
                    content: funFact,
                    icon: "sparkles"
                )
            }
            
            if let trivia = enrichmentData.songTrivia, !trivia.isEmpty {
                EnrichmentSectionView(
                    title: "Song Trivia",
                    content: trivia,
                    icon: "music.note"
                )
            }
            
            if let releaseInfo = enrichmentData.formattedReleaseInfo {
                EnrichmentSectionView(
                    title: "Release Info",
                    content: releaseInfo,
                    icon: "calendar"
                )
            }
            
            if !enrichmentData.genres.isEmpty {
                genresSection(enrichmentData.genres)
            }
        }
    }
    
    private func genresSection(_ genres: [String]) -> some View {
        VStack(alignment: .leading, spacing: CGFloat.MusicNerd.sm) {
            HStack {
                Image(systemName: "music.mic")
                    .foregroundColor(Color.MusicNerd.primary)
                Text("Genres")
                    .musicNerdStyle(.headlineSmall())
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: CGFloat.MusicNerd.xs) {
                ForEach(genres, id: \.self) { genre in
                    Text(genre)
                        .musicNerdStyle(.caption())
                        .padding(.horizontal, CGFloat.MusicNerd.sm)
                        .padding(.vertical, CGFloat.MusicNerd.xs)
                        .background(Color.MusicNerd.accent.opacity(0.2))
                        .foregroundColor(Color.MusicNerd.accent)
                        .cornerRadius(CGFloat.BorderRadius.sm)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CGFloat.MusicNerd.md)
        .background(Color.MusicNerd.cardBackground)
        .cornerRadius(CGFloat.BorderRadius.md)
    }
    
    private var loadingSection: some View {
        VStack(spacing: CGFloat.MusicNerd.md) {
            Image(systemName: "hourglass")
                .font(.system(size: 40))
                .foregroundColor(Color.MusicNerd.textSecondary)
            
            Text("Getting Music Nerd Insights...")
                .musicNerdStyle(.headlineSmall(color: Color.MusicNerd.textSecondary))
            
            Text("We're gathering interesting details about this track and artist.")
                .musicNerdStyle(.bodyMedium(color: Color.MusicNerd.textSecondary))
                .multilineTextAlignment(.center)
        }
        .padding(CGFloat.MusicNerd.lg)
        .background(Color.MusicNerd.cardBackground)
        .cornerRadius(CGFloat.BorderRadius.md)
    }
    
    private func funFactSections(_ funFacts: [String: String]) -> some View {
        let funFactConfig: [(type: String, title: String, icon: String)] = [
            ("lore", "Artist Lore", "book.closed"),
            ("bts", "Behind the Scenes", "eye"),
            ("activity", "Artist Activity", "music.note.list"),
            ("surprise", "Surprise Fact", "sparkles")
        ]
        
        return LazyVStack(spacing: CGFloat.MusicNerd.lg) {
            ForEach(funFactConfig, id: \.type) { config in
                if let fact = funFacts[config.type], !fact.isEmpty {
                    EnrichmentSectionView(
                        title: config.title,
                        content: fact,
                        icon: config.icon
                    )
                }
            }
        }
    }
    
    private func funFactSectionsWithFallbacks(_ funFacts: [String: String], errors: [String: EnrichmentError]) -> some View {
        let funFactConfig: [(type: String, title: String, icon: String)] = [
            ("lore", "Artist Lore", "book.closed"),
            ("bts", "Behind the Scenes", "eye"),
            ("activity", "Artist Activity", "music.note.list"),
            ("surprise", "Surprise Fact", "sparkles")
        ]
        
        return LazyVStack(spacing: CGFloat.MusicNerd.lg) {
            ForEach(funFactConfig, id: \.type) { config in
                if let fact = funFacts[config.type], !fact.isEmpty {
                    EnrichmentSectionView(
                        title: config.title,
                        content: fact,
                        icon: config.icon
                    )
                } else if let error = errors[config.type] {
                    FallbackSectionView(
                        title: config.title,
                        errorMessage: error.fallbackMessage,
                        icon: config.icon,
                        isRetryable: error.isRetryable,
                        isRetrying: isRetrying,
                        onRetry: { retryEnrichment() }
                    )
                }
            }
        }
    }
    
    private func retryEnrichment() {
        guard !isRetrying else { return }
        
        Task { @MainActor in
            isRetrying = true
            retryCount += 1
            
            print("Retry enrichment requested for: '\(match.title)' (attempt #\(retryCount))")
            
            let enrichmentResult = await services.openAIService.enrichSong(match)
            
            switch enrichmentResult {
            case .success(let enrichmentData):
                print("Retry enrichment successful - updating song match")
                
                // Update the match with new enrichment data
                match.enrichmentData = enrichmentData
                
                // Save the updated match
                let saveResult = await services.storageService.save(match)
                switch saveResult {
                case .success:
                    print("Re-enriched song match saved successfully")
                case .failure(let error):
                    print("Failed to save re-enriched song match: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print("Retry enrichment failed: \(error.localizedDescription)")
            }
            
            isRetrying = false
        }
    }
    
    private var shareText: String {
        var text = "🎵 I just discovered: \(match.title) by \(match.artist)"
        
        if let enrichmentData = match.enrichmentData {
            // Try to get the best fun fact for sharing
            if let surpriseFact = enrichmentData.surpriseFact {
                text += "\n\n🤓 Surprise Fact: \(surpriseFact)"
            } else if let loreFact = enrichmentData.loreFact {
                text += "\n\n📚 Artist Lore: \(loreFact)"
            } else if let funFact = enrichmentData.funFact {
                text += "\n\n🤓 Music Nerd Insight: \(funFact)"
            }
        }
        
        text += "\n\nShared from TrackNerd 🎧"
        return text
    }
}

struct EnrichmentSectionView: View {
    let title: String
    let content: String
    let icon: String
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: CGFloat.MusicNerd.sm) {
            Button(action: { 
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(Color.MusicNerd.primary)
                    
                    Text(title)
                        .musicNerdStyle(.headlineSmall())
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(Color.MusicNerd.textSecondary)
                        .font(.caption)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(content)
                    .musicNerdStyle(.bodyMedium())
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CGFloat.MusicNerd.md)
        .background(Color.MusicNerd.cardBackground)
        .cornerRadius(CGFloat.BorderRadius.md)
    }
}

struct FallbackSectionView: View {
    let title: String
    let errorMessage: String
    let icon: String
    let isRetryable: Bool
    let isRetrying: Bool
    let onRetry: () -> Void
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: CGFloat.MusicNerd.sm) {
            Button(action: { 
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(Color.MusicNerd.textSecondary)
                    
                    Text(title)
                        .musicNerdStyle(.headlineSmall(color: Color.MusicNerd.textSecondary))
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(Color.MusicNerd.textSecondary)
                        .font(.caption)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: CGFloat.MusicNerd.sm) {
                    Text(errorMessage)
                        .musicNerdStyle(.bodyMedium(color: Color.MusicNerd.textSecondary))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if isRetryable {
                        Button(action: onRetry) {
                            HStack(spacing: CGFloat.MusicNerd.xs) {
                                if isRetrying {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color.MusicNerd.primary))
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption)
                                }
                                Text(isRetrying ? "Retrying..." : "Retry")
                                    .musicNerdStyle(.caption())
                            }
                            .padding(.horizontal, CGFloat.MusicNerd.sm)
                            .padding(.vertical, CGFloat.MusicNerd.xs)
                            .background(Color.MusicNerd.primary.opacity(isRetrying ? 0.05 : 0.1))
                            .foregroundColor(isRetrying ? Color.MusicNerd.textSecondary : Color.MusicNerd.primary)
                            .cornerRadius(CGFloat.BorderRadius.sm)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(isRetrying)
                    }
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CGFloat.MusicNerd.md)
        .background(Color.MusicNerd.cardBackground.opacity(0.5))
        .cornerRadius(CGFloat.BorderRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: CGFloat.BorderRadius.md)
                .stroke(Color.MusicNerd.textSecondary.opacity(0.2), lineWidth: 1)
        )
    }
}


struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    MatchDetailView(
        match: SongMatch(
            title: "Bohemian Rhapsody",
            artist: "Queen",
            album: "A Night at the Opera",
            enrichmentData: EnrichmentData(
                artistBio: "Queen are a British rock band formed in London in 1970. Their classic line-up was Freddie Mercury (lead vocals, piano), Brian May (guitar, vocals), Roger Taylor (drums, vocals) and John Deacon (bass).",
                songTrivia: "This epic 6-minute operatic rock masterpiece was written entirely by Freddie Mercury and is considered one of the greatest songs of all time.",
                funFact: "The song's famous operatic section includes the made-up words 'Bismillah' (which actually means 'in the name of God' in Arabic) and references to Scaramouche, a stock character from Italian opera.",
                funFacts: [
                    "lore": "Freddie Mercury wrote this song on piano, despite being primarily a vocalist. He had no formal musical training but composed one of rock's most complex arrangements entirely by ear.",
                    "bts": "The song was recorded using innovative 24-track technology and required over 180 vocal overdubs. The famous operatic section took three weeks to record.",
                    "activity": "Queen performed this song live only a handful of times due to its complexity. The Live Aid performance famously skipped the operatic section.",
                    "surprise": "The title 'Bohemian Rhapsody' was chosen because Freddie loved the word 'rhapsody' and thought 'bohemian' perfectly described the band's artistic freedom."
                ],
                genres: ["Rock", "Progressive Rock", "Opera Rock"],
                releaseYear: 1975,
                albumName: "A Night at the Opera"
            )
        )
    )
}