import SwiftUI

struct MusicNerdButton: View {
    let title: String
    let action: () -> Void
    var style: ButtonStyle = .primary
    var size: ButtonSize = .medium
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var icon: String? = nil
    
    enum ButtonStyle {
        case primary
        case secondary
        case outline
        case ghost
        case destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return Color.MusicNerd.primary
            case .secondary: return Color.MusicNerd.accent
            case .outline, .ghost: return Color.clear
            case .destructive: return Color.MusicNerd.error
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .destructive: return Color.MusicNerd.textInverse
            case .secondary: return Color.MusicNerd.text
            case .outline, .ghost: return Color.MusicNerd.primary
            }
        }
        
        var borderColor: Color {
            switch self {
            case .outline: return Color.MusicNerd.primary
            case .ghost: return Color.clear
            default: return Color.clear
            }
        }
        
        var borderWidth: CGFloat {
            switch self {
            case .outline: return 1.5
            default: return 0
            }
        }
    }
    
    enum ButtonSize {
        case small
        case medium
        case large
        
        var height: CGFloat {
            switch self {
            case .small: return 36
            case .medium: return 44
            case .large: return 52
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return CGFloat.MusicNerd.sm
            case .medium: return CGFloat.MusicNerd.md
            case .large: return CGFloat.MusicNerd.lg
            }
        }
        
        var font: Font {
            switch self {
            case .small: return Font.MusicNerd.labelMedium
            case .medium: return Font.MusicNerd.labelLarge
            case .large: return Font.MusicNerd.titleMedium
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 16
            case .large: return 18
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: CGFloat.MusicNerd.xs) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .medium))
                }
                
                Text(title)
                    .font(size.font)
                    .fontWeight(.medium)
            }
            .foregroundColor(isEnabled ? style.foregroundColor : Color.MusicNerd.textSecondary)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: CGFloat.BorderRadius.button)
                    .fill(isEnabled ? style.backgroundColor : Color.MusicNerd.buttonDisabled)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat.BorderRadius.button)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
            .scaleEffect(isEnabled ? 1.0 : 0.95)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
        }
        .disabled(!isEnabled || isLoading)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Haptic Feedback Button Style
struct HapticButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .brightness(configuration.isPressed ? -0.1 : 0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onTapGesture {
                if true {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            }
    }
}

// MARK: - Preview
#Preview("Music Nerd Buttons") {
    ScrollView {
        VStack(spacing: CGFloat.MusicNerd.lg) {
            // Button Styles
            VStack(spacing: CGFloat.MusicNerd.md) {
                Text("Button Styles")
                    .musicNerdStyle(.headlineMedium())
                
                MusicNerdButton(title: "Primary", action: {})
                MusicNerdButton(title: "Secondary", action: {}, style: .secondary)
                MusicNerdButton(title: "Outline", action: {}, style: .outline)
                MusicNerdButton(title: "Ghost", action: {}, style: .ghost)
                MusicNerdButton(title: "Destructive", action: {}, style: .destructive)
            }
            
            Divider()
            
            // Button Sizes
            VStack(spacing: CGFloat.MusicNerd.md) {
                Text("Button Sizes")
                    .musicNerdStyle(.headlineMedium())
                
                MusicNerdButton(title: "Small", action: {}, size: .small)
                MusicNerdButton(title: "Medium", action: {}, size: .medium)
                MusicNerdButton(title: "Large", action: {}, size: .large)
            }
            
            Divider()
            
            // Button States
            VStack(spacing: CGFloat.MusicNerd.md) {
                Text("Button States")
                    .musicNerdStyle(.headlineMedium())
                
                MusicNerdButton(title: "Enabled", action: {})
                MusicNerdButton(title: "Disabled", action: {}, isEnabled: false)
                MusicNerdButton(title: "Loading", action: {}, isLoading: true)
                MusicNerdButton(title: "With Icon", action: {}, icon: "music.note")
            }
        }
        .padding()
    }
    .background(Color.MusicNerd.background)
}