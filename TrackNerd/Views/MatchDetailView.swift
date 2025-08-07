//
//  MatchDetailView.swift
//  TrackNerd
//
//  Created by Carl Tydingco on 8/7/25.
//

import SwiftUI

struct MatchDetailView: View {
    let match: SongMatch
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: CGFloat.MusicNerd.lg) {
                    headerSection
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
    
    private func enrichmentSections(_ enrichmentData: EnrichmentData) -> some View {
        LazyVStack(spacing: CGFloat.MusicNerd.lg) {
            if let bio = enrichmentData.artistBio, !bio.isEmpty {
                EnrichmentSectionView(
                    title: "About \(match.artist)",
                    content: bio,
                    icon: "person.circle"
                )
            }
            
            if let funFact = enrichmentData.funFact, !funFact.isEmpty {
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
    
    private var shareText: String {
        var text = "🎵 I just discovered: \(match.title) by \(match.artist)"
        
        if let enrichmentData = match.enrichmentData {
            if let funFact = enrichmentData.funFact {
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
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
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
                    .transition(.opacity.combined(with: .slide))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CGFloat.MusicNerd.md)
        .background(Color.MusicNerd.cardBackground)
        .cornerRadius(CGFloat.BorderRadius.md)
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
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
                genres: ["Rock", "Progressive Rock", "Opera Rock"],
                releaseYear: 1975,
                albumName: "A Night at the Opera"
            )
        )
    )
}