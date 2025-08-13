import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject private var appleMusic: AppleMusicService
    var onTap: (() -> Void)?
    
    private var isVisible: Bool {
        appleMusic.currentMatch != nil || appleMusic.isPlayingPreview || appleMusic.isPlayingFull
    }
    
    var body: some View {
        if isVisible {
            Button(action: { onTap?() }) {
                HStack(spacing: CGFloat.MusicNerd.sm) {
                    // Artwork
                    AlbumArtworkView(url: appleMusic.currentMatch?.albumArtURL, size: 40)
                    
                    // Title/artist + source badge
                    VStack(alignment: .leading, spacing: 2) {
                        Text(appleMusic.currentMatch?.title ?? "Now Playing")
                            .musicNerdStyle(.bodyMedium())
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            Text(appleMusic.currentMatch?.artist ?? "")
                                .musicNerdStyle(.caption(color: Color.MusicNerd.textSecondary))
                                .lineLimit(1)
                            SourceBadge(isFull: appleMusic.isPlayingFull)
                        }
                    }
                    
                    Spacer()
                    
                    // Play/Pause
                    Button(action: {
                        if appleMusic.isPlayingFull {
                            appleMusic.pauseFullIfNeeded()
                        } else if appleMusic.isPlayingPreview {
                            appleMusic.pause()
                        } else {
                            // No-op: playback initiation happens from detail card/buttons
                        }
                    }) {
                        Image(systemName: (appleMusic.isPlayingFull || appleMusic.isPlayingPreview) ? "pause.fill" : "play.fill")
                            .foregroundColor(Color.MusicNerd.primary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, CGFloat.MusicNerd.md)
                .padding(.vertical, CGFloat.MusicNerd.sm)
                .background(.ultraThinMaterial)
                .cornerRadius(CGFloat.BorderRadius.md)
                .overlay(
                    ProgressView(value: appleMusic.isPlayingFull ? appleMusic.fullProgress : appleMusic.previewProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.MusicNerd.primary))
                        .frame(height: 2)
                        .padding(.top, 48)
                    , alignment: .top
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("mini-player")
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

private struct SourceBadge: View {
    let isFull: Bool
    var body: some View {
        Text(isFull ? "Apple Music" : "Preview")
            .musicNerdStyle(.caption())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background((isFull ? Color.MusicNerd.primary : Color.MusicNerd.accent).opacity(0.15))
            .foregroundColor(isFull ? Color.MusicNerd.primary : Color.MusicNerd.accent)
            .cornerRadius(CGFloat.BorderRadius.xs)
    }
}

#Preview {
    MiniPlayerView(onTap: {})
        .environmentObject(DefaultServiceContainer.shared.appleMusicServiceObject)
        .padding()
        .background(Color.MusicNerd.background)
}
