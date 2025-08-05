import SwiftUI

extension Font {
    
    struct MusicNerd {
        // Display fonts - for large headings and hero text
        static let displayLarge = Font.system(size: 32, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
        static let displaySmall = Font.system(size: 24, weight: .bold, design: .rounded)
        
        // Headline fonts - for section headers
        static let headlineLarge = Font.system(size: 22, weight: .semibold, design: .default)
        static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .default)
        static let headlineSmall = Font.system(size: 18, weight: .semibold, design: .default)
        
        // Title fonts - for card titles and important content
        static let titleLarge = Font.system(size: 16, weight: .medium, design: .default)
        static let titleMedium = Font.system(size: 14, weight: .medium, design: .default)
        static let titleSmall = Font.system(size: 12, weight: .medium, design: .default)
        
        // Body fonts - for main content
        static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
        
        // Label fonts - for buttons and small labels
        static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
        static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 10, weight: .medium, design: .default)
        
        // Caption fonts - for metadata and timestamps
        static let caption = Font.system(size: 11, weight: .regular, design: .default)
        static let captionBold = Font.system(size: 11, weight: .semibold, design: .default)
        
        // Monospace fonts - for technical content
        static let mono = Font.system(size: 14, weight: .regular, design: .monospaced)
        static let monoSmall = Font.system(size: 12, weight: .regular, design: .monospaced)
    }
}

// MARK: - Text Styles
extension Text {
    
    func musicNerdStyle(_ style: MusicNerdTextStyle) -> some View {
        self
            .font(style.font)
            .foregroundColor(style.color)
            .lineSpacing(style.lineSpacing)
    }
}

enum MusicNerdTextStyle {
    case displayLarge(color: Color = Color.MusicNerd.text)
    case displayMedium(color: Color = Color.MusicNerd.text)
    case displaySmall(color: Color = Color.MusicNerd.text)
    
    case headlineLarge(color: Color = Color.MusicNerd.text)
    case headlineMedium(color: Color = Color.MusicNerd.text)
    case headlineSmall(color: Color = Color.MusicNerd.text)
    
    case titleLarge(color: Color = Color.MusicNerd.text)
    case titleMedium(color: Color = Color.MusicNerd.text)
    case titleSmall(color: Color = Color.MusicNerd.text)
    
    case bodyLarge(color: Color = Color.MusicNerd.text)
    case bodyMedium(color: Color = Color.MusicNerd.text)
    case bodySmall(color: Color = Color.MusicNerd.text)
    
    case labelLarge(color: Color = Color.MusicNerd.text)
    case labelMedium(color: Color = Color.MusicNerd.text)
    case labelSmall(color: Color = Color.MusicNerd.text)
    
    case caption(color: Color = Color.MusicNerd.textSecondary)
    case captionBold(color: Color = Color.MusicNerd.textSecondary)
    
    var font: Font {
        switch self {
        case .displayLarge: return Font.MusicNerd.displayLarge
        case .displayMedium: return Font.MusicNerd.displayMedium
        case .displaySmall: return Font.MusicNerd.displaySmall
        case .headlineLarge: return Font.MusicNerd.headlineLarge
        case .headlineMedium: return Font.MusicNerd.headlineMedium
        case .headlineSmall: return Font.MusicNerd.headlineSmall
        case .titleLarge: return Font.MusicNerd.titleLarge
        case .titleMedium: return Font.MusicNerd.titleMedium
        case .titleSmall: return Font.MusicNerd.titleSmall
        case .bodyLarge: return Font.MusicNerd.bodyLarge
        case .bodyMedium: return Font.MusicNerd.bodyMedium
        case .bodySmall: return Font.MusicNerd.bodySmall
        case .labelLarge: return Font.MusicNerd.labelLarge
        case .labelMedium: return Font.MusicNerd.labelMedium
        case .labelSmall: return Font.MusicNerd.labelSmall
        case .caption: return Font.MusicNerd.caption
        case .captionBold: return Font.MusicNerd.captionBold
        }
    }
    
    var color: Color {
        switch self {
        case .displayLarge(let color), .displayMedium(let color), .displaySmall(let color),
             .headlineLarge(let color), .headlineMedium(let color), .headlineSmall(let color),
             .titleLarge(let color), .titleMedium(let color), .titleSmall(let color),
             .bodyLarge(let color), .bodyMedium(let color), .bodySmall(let color),
             .labelLarge(let color), .labelMedium(let color), .labelSmall(let color),
             .caption(let color), .captionBold(let color):
            return color
        }
    }
    
    var lineSpacing: CGFloat {
        switch self {
        case .displayLarge, .displayMedium, .displaySmall:
            return 4
        case .headlineLarge, .headlineMedium, .headlineSmall:
            return 2
        case .bodyLarge, .bodyMedium:
            return 1
        default:
            return 0
        }
    }
}

// MARK: - Typography Preview
#Preview("Music Nerd Typography") {
    ScrollView {
        VStack(alignment: .leading, spacing: AppConfiguration.UI.Spacing.lg) {
            Group {
                Text("Display Large")
                    .musicNerdStyle(.displayLarge())
                Text("Display Medium")
                    .musicNerdStyle(.displayMedium())
                Text("Display Small")
                    .musicNerdStyle(.displaySmall())
            }
            
            Divider()
            
            Group {
                Text("Headline Large")
                    .musicNerdStyle(.headlineLarge())
                Text("Headline Medium")
                    .musicNerdStyle(.headlineMedium())
                Text("Headline Small")
                    .musicNerdStyle(.headlineSmall())
            }
            
            Divider()
            
            Group {
                Text("Title Large")
                    .musicNerdStyle(.titleLarge())
                Text("Title Medium")
                    .musicNerdStyle(.titleMedium())
                Text("Title Small")
                    .musicNerdStyle(.titleSmall())
            }
            
            Divider()
            
            Group {
                Text("Body Large - This is the main body text used for paragraphs and longer content.")
                    .musicNerdStyle(.bodyLarge())
                Text("Body Medium - This is medium body text for secondary content.")
                    .musicNerdStyle(.bodyMedium())
                Text("Body Small - This is small body text for compact layouts.")
                    .musicNerdStyle(.bodySmall())
            }
            
            Divider()
            
            Group {
                Text("Label Large")
                    .musicNerdStyle(.labelLarge())
                Text("Label Medium")
                    .musicNerdStyle(.labelMedium())
                Text("Label Small")
                    .musicNerdStyle(.labelSmall())
            }
            
            Divider()
            
            Group {
                Text("Caption text")
                    .musicNerdStyle(.caption())
                Text("Caption Bold")
                    .musicNerdStyle(.captionBold())
            }
        }
        .padding()
    }
    .background(Color.MusicNerd.background)
}