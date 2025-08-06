import SwiftUI

struct MusicNerdCard<Content: View>: View {
    let content: Content
    var style: CardStyle = .default
    var padding: CGFloat = CGFloat.MusicNerd.md
    var cornerRadius: CGFloat = CGFloat.BorderRadius.md
    var shadowEnabled: Bool = true
    
    enum CardStyle {
        case `default`
        case elevated
        case outline
        case filled
        
        var backgroundColor: Color {
            switch self {
            case .default, .elevated: return Color.MusicNerd.surface
            case .outline: return Color.clear
            case .filled: return Color.MusicNerd.accent.opacity(0.1)
            }
        }
        
        var borderColor: Color {
            switch self {
            case .outline: return Color.MusicNerd.accent
            default: return Color.clear
            }
        }
        
        var borderWidth: CGFloat {
            switch self {
            case .outline: return 1
            default: return 0
            }
        }
        
        var shadowRadius: CGFloat {
            switch self {
            case .elevated: return 8
            case .default: return 2
            default: return 0
            }
        }
        
        var shadowOpacity: Double {
            switch self {
            case .elevated: return 0.15
            case .default: return 0.05
            default: return 0
            }
        }
    }
    
    init(
        style: CardStyle = .default,
        padding: CGFloat = CGFloat.MusicNerd.md,
        cornerRadius: CGFloat = CGFloat.BorderRadius.md,
        shadowEnabled: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowEnabled = shadowEnabled
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(style.backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
            .shadow(
                color: shadowEnabled ? Color.black.opacity(style.shadowOpacity) : Color.clear,
                radius: style.shadowRadius,
                x: 0,
                y: style.shadowRadius / 4
            )
    }
}

// MARK: - Song Match Card
struct SongMatchCard: View {
    let match: SongMatch
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        MusicNerdCard(style: .default) {
            HStack(spacing: CGFloat.MusicNerd.md) {
                // Album artwork
                AlbumArtworkView(
                    url: match.albumArtURL,
                    size: 60
                )
                
                VStack(alignment: .leading, spacing: CGFloat.MusicNerd.xs) {
                    Text(match.title)
                        .musicNerdStyle(.titleMedium())
                        .lineLimit(1)
                    
                    Text(match.artist)
                        .musicNerdStyle(.bodyMedium(color: Color.MusicNerd.textSecondary))
                        .lineLimit(1)
                    
                    HStack {
                        Text(match.formattedMatchDate)
                            .musicNerdStyle(.caption())
                        
                        Spacer()
                        
                        if match.hasEnrichment {
                            Image(systemName: "sparkles")
                                .foregroundColor(Color.MusicNerd.primary)
                                .font(.caption)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.MusicNerd.textSecondary)
                    .font(.caption)
            }
        }
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Loading Card
struct LoadingCard: View {
    var body: some View {
        MusicNerdCard {
            HStack(spacing: CGFloat.MusicNerd.md) {
                // Shimmer effect for artwork
                RoundedRectangle(cornerRadius: CGFloat.BorderRadius.image)
                    .fill(Color.MusicNerd.accent.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .shimmer()
                
                VStack(alignment: .leading, spacing: CGFloat.MusicNerd.xs) {
                    // Shimmer effect for title
                    Rectangle()
                        .fill(Color.MusicNerd.accent.opacity(0.3))
                        .frame(height: 16)
                        .cornerRadius(CGFloat.BorderRadius.xs)
                        .shimmer(delay: 0.1)
                    
                    // Shimmer effect for artist
                    Rectangle()
                        .fill(Color.MusicNerd.accent.opacity(0.3))
                        .frame(width: 120, height: 14)
                        .cornerRadius(CGFloat.BorderRadius.xs)
                        .shimmer(delay: 0.2)
                    
                    // Shimmer effect for date
                    Rectangle()
                        .fill(Color.MusicNerd.accent.opacity(0.3))
                        .frame(width: 80, height: 12)
                        .cornerRadius(CGFloat.BorderRadius.xs)
                        .shimmer(delay: 0.3)
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Shimmer Effect
struct ShimmerEffect: ViewModifier {
    @State private var isAnimating = false
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.5 : 1.0)
            .animation(
                Animation
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

extension View {
    func shimmer(delay: Double = 0) -> some View {
        modifier(ShimmerEffect(delay: delay))
    }
}

// MARK: - Album Artwork View
struct AlbumArtworkView: View {
    let url: String?
    let size: CGFloat
    
    var body: some View {
        Group {
            if let urlString = url, let imageURL = URL(string: urlString) {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    artworkPlaceholder
                }
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: CGFloat.BorderRadius.image))
            } else {
                artworkPlaceholder
            }
        }
    }
    
    private var artworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: CGFloat.BorderRadius.image)
            .fill(Color.MusicNerd.accent.opacity(0.3))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "music.note")
                    .foregroundColor(Color.MusicNerd.primary)
                    .font(.title2)
            )
    }
}

// MARK: - Preview
#Preview("Music Nerd Cards") {
    ScrollView {
        VStack(spacing: CGFloat.MusicNerd.lg) {
            // Card Styles
            VStack(spacing: CGFloat.MusicNerd.md) {
                Text("Card Styles")
                    .musicNerdStyle(.headlineMedium())
                
                MusicNerdCard {
                    Text("Default Card")
                        .musicNerdStyle(.bodyMedium())
                }
                
                MusicNerdCard(style: .elevated) {
                    Text("Elevated Card")
                        .musicNerdStyle(.bodyMedium())
                }
                
                MusicNerdCard(style: .outline) {
                    Text("Outline Card")
                        .musicNerdStyle(.bodyMedium())
                }
                
                MusicNerdCard(style: .filled) {
                    Text("Filled Card")
                        .musicNerdStyle(.bodyMedium())
                }
            }
            
            Divider()
            
            // Song Match Cards
            VStack(spacing: CGFloat.MusicNerd.md) {
                Text("Song Match Cards")
                    .musicNerdStyle(.headlineMedium())
                
                SongMatchCard(
                    match: SongMatch(
                        title: "Bohemian Rhapsody",
                        artist: "Queen",
                        albumArtURL: "https://i.scdn.co/image/ab67616d0000b273e319baafd16e84f0408af2a0",
                        enrichmentData: EnrichmentData(artistBio: "British rock band")
                    )
                )
                
                SongMatchCard(
                    match: SongMatch(
                        title: "Hotel California",
                        artist: "Eagles"
                    )
                )
                
                LoadingCard()
            }
        }
        .padding()
    }
    .background(Color.MusicNerd.background)
}