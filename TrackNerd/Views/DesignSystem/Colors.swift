import SwiftUI

extension Color {
    
    struct MusicNerd {
        // Primary brand colors
        static let primary = Color(hex: "#FF69B4")           // Hot Pink
        static let secondary = Color(hex: "#FF1493")         // Deep Pink
        static let accent = Color(hex: "#FFB6C1")            // Light Pink
        
        // Background colors
        static let background = Color(hex: "#FFEEF8")        // Light Pink Background
        static let surface = Color.white
        static let cardBackground = Color.white
        static let overlay = Color.black.opacity(0.6)
        
        // Text colors
        static let text = Color(hex: "#2C2C2E")              // Primary Text
        static let textSecondary = Color(hex: "#8E8E93")     // Secondary Text
        static let textInverse = Color.white
        
        // Status colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Interactive states
        static let buttonPrimary = primary
        static let buttonSecondary = accent
        static let buttonDisabled = Color.gray.opacity(0.3)
        
        // Waveform and audio visualization
        static let waveformActive = primary
        static let waveformInactive = accent.opacity(0.3)
    }
}

// Helper extension for hex color initialization
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Color Previews
#Preview("Music Nerd Colors") {
    ScrollView {
        VStack(spacing: CGFloat.MusicNerd.md) {
            Group {
                ColorSwatch("Primary", color: Color.MusicNerd.primary)
                ColorSwatch("Secondary", color: Color.MusicNerd.secondary)
                ColorSwatch("Accent", color: Color.MusicNerd.accent)
            }
            
            Group {
                ColorSwatch("Background", color: Color.MusicNerd.background)
                ColorSwatch("Surface", color: Color.MusicNerd.surface)
                ColorSwatch("Text", color: Color.MusicNerd.text)
                ColorSwatch("Text Secondary", color: Color.MusicNerd.textSecondary)
            }
            
            Group {
                ColorSwatch("Success", color: Color.MusicNerd.success)
                ColorSwatch("Warning", color: Color.MusicNerd.warning)
                ColorSwatch("Error", color: Color.MusicNerd.error)
                ColorSwatch("Info", color: Color.MusicNerd.info)
            }
        }
        .padding()
    }
    .background(Color.MusicNerd.background)
}

private struct ColorSwatch: View {
    let name: String
    let color: Color
    
    init(_ name: String, color: Color) {
        self.name = name
        self.color = color
    }
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(color)
                .frame(width: 50, height: 50)
                .cornerRadius(CGFloat.BorderRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: CGFloat.BorderRadius.sm)
                        .stroke(Color.MusicNerd.text.opacity(0.2), lineWidth: 1)
                )
            
            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)
                    .foregroundColor(Color.MusicNerd.text)
                Text(color.description)
                    .font(.caption)
                    .foregroundColor(Color.MusicNerd.textSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.MusicNerd.surface)
        .cornerRadius(CGFloat.BorderRadius.md)
    }
}