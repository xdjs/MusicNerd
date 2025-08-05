import SwiftUI

// MARK: - Spacing System
extension CGFloat {
    struct MusicNerd {
        // Base spacing unit (4pt)
        static let unit: CGFloat = 4
        
        // Spacing scale
        static let xs: CGFloat = unit * 1    // 4pt
        static let sm: CGFloat = unit * 2    // 8pt
        static let md: CGFloat = unit * 4    // 16pt
        static let lg: CGFloat = unit * 6    // 24pt
        static let xl: CGFloat = unit * 8    // 32pt
        static let xxl: CGFloat = unit * 12  // 48pt
        static let xxxl: CGFloat = unit * 16 // 64pt
        
        // Component-specific spacing
        static let cardPadding: CGFloat = md
        static let buttonPadding: CGFloat = md
        static let sectionSpacing: CGFloat = xl
        static let itemSpacing: CGFloat = sm
        
        // Layout margins
        static let screenMargin: CGFloat = md
        static let contentMargin: CGFloat = lg
    }
}

// MARK: - Border Radius System
extension CGFloat {
    struct BorderRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let round: CGFloat = 999 // For fully rounded elements
        
        // Component-specific radius
        static let button: CGFloat = sm
        static let card: CGFloat = md
        static let image: CGFloat = sm
        static let sheet: CGFloat = lg
    }
}

// MARK: - Shadow System
struct MusicNerdShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    let opacity: Double
    
    static let none = MusicNerdShadow(
        color: .clear,
        radius: 0,
        x: 0,
        y: 0,
        opacity: 0
    )
    
    static let subtle = MusicNerdShadow(
        color: .black,
        radius: 2,
        x: 0,
        y: 1,
        opacity: 0.05
    )
    
    static let soft = MusicNerdShadow(
        color: .black,
        radius: 4,
        x: 0,
        y: 2,
        opacity: 0.1
    )
    
    static let medium = MusicNerdShadow(
        color: .black,
        radius: 8,
        x: 0,
        y: 4,
        opacity: 0.15
    )
    
    static let strong = MusicNerdShadow(
        color: .black,
        radius: 16,
        x: 0,
        y: 8,
        opacity: 0.2
    )
    
    static let intense = MusicNerdShadow(
        color: .black,
        radius: 24,
        x: 0,
        y: 12,
        opacity: 0.25
    )
}

// MARK: - View Extensions for Consistent Styling
extension View {
    
    // Apply Music Nerd shadow
    func musicNerdShadow(_ shadow: MusicNerdShadow) -> some View {
        self.shadow(
            color: shadow.color.opacity(shadow.opacity),
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    // Standard card styling
    func cardStyle(
        backgroundColor: Color = Color.MusicNerd.surface,
        cornerRadius: CGFloat = CGFloat.BorderRadius.card,
        shadow: MusicNerdShadow = .soft
    ) -> some View {
        self
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .musicNerdShadow(shadow)
    }
    
    // Standard section spacing
    func sectionSpacing() -> some View {
        self.padding(.vertical, CGFloat.MusicNerd.sectionSpacing)
    }
    
    // Screen margin padding
    func screenPadding() -> some View {
        self.padding(.horizontal, CGFloat.MusicNerd.screenMargin)
    }
    
    // Content margin padding
    func contentPadding() -> some View {
        self.padding(CGFloat.MusicNerd.contentMargin)
    }
    
    // Standard item spacing in stacks
    func itemSpacing() -> some View {
        self.padding(.vertical, CGFloat.MusicNerd.itemSpacing)
    }
}

// MARK: - Layout Containers
struct MusicNerdSection<Content: View>: View {
    let title: String?
    let content: Content
    
    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: CGFloat.MusicNerd.md) {
            if let title = title {
                Text(title)
                    .musicNerdStyle(.headlineMedium())
                    .screenPadding()
            }
            
            content
        }
        .sectionSpacing()
    }
}

struct MusicNerdContainer<Content: View>: View {
    let content: Content
    var backgroundColor: Color = Color.MusicNerd.background
    
    init(backgroundColor: Color = Color.MusicNerd.background, @ViewBuilder content: () -> Content) {
        self.backgroundColor = backgroundColor
        self.content = content()
    }
    
    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundColor)
    }
}

// MARK: - Consistent Layout Modifiers
struct ConsistentListRow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, CGFloat.MusicNerd.screenMargin)
            .padding(.vertical, CGFloat.MusicNerd.itemSpacing)
            .background(Color.MusicNerd.surface)
    }
}

struct ConsistentCard: ViewModifier {
    let style: MusicNerdCard<AnyView>.CardStyle
    
    func body(content: Content) -> some View {
        content
            .padding(CGFloat.MusicNerd.cardPadding)
            .cardStyle(cornerRadius: CGFloat.BorderRadius.card)
    }
}

extension View {
    func consistentListRow() -> some View {
        modifier(ConsistentListRow())
    }
    
    func consistentCard(style: MusicNerdCard<AnyView>.CardStyle = .default) -> some View {
        modifier(ConsistentCard(style: style))
    }
}

// MARK: - Responsive Spacing
struct ResponsiveSpacing {
    static func horizontal(for screenWidth: CGFloat) -> CGFloat {
        switch screenWidth {
        case 0..<320:
            return CGFloat.MusicNerd.sm
        case 320..<768:
            return CGFloat.MusicNerd.md
        default:
            return CGFloat.MusicNerd.lg
        }
    }
    
    static func vertical(for screenHeight: CGFloat) -> CGFloat {
        switch screenHeight {
        case 0..<600:
            return CGFloat.MusicNerd.sm
        case 600..<800:
            return CGFloat.MusicNerd.md
        default:
            return CGFloat.MusicNerd.lg
        }
    }
}

// MARK: - Preview
#Preview("Spacing & Styling System") {
    ScrollView {
        MusicNerdContainer {
            VStack(spacing: 0) {
                // Spacing Demo
                MusicNerdSection(title: "Spacing Scale") {
                    VStack(alignment: .leading, spacing: CGFloat.MusicNerd.sm) {
                        SpacingDemo(name: "XS", value: CGFloat.MusicNerd.xs)
                        SpacingDemo(name: "SM", value: CGFloat.MusicNerd.sm)
                        SpacingDemo(name: "MD", value: CGFloat.MusicNerd.md)
                        SpacingDemo(name: "LG", value: CGFloat.MusicNerd.lg)
                        SpacingDemo(name: "XL", value: CGFloat.MusicNerd.xl)
                        SpacingDemo(name: "XXL", value: CGFloat.MusicNerd.xxl)
                    }
                    .screenPadding()
                }
                
                // Border Radius Demo
                MusicNerdSection(title: "Border Radius") {
                    VStack(spacing: CGFloat.MusicNerd.md) {
                        HStack(spacing: CGFloat.MusicNerd.md) {
                            BorderRadiusDemo(name: "XS", radius: CGFloat.BorderRadius.xs)
                            BorderRadiusDemo(name: "SM", radius: CGFloat.BorderRadius.sm)
                            BorderRadiusDemo(name: "MD", radius: CGFloat.BorderRadius.md)
                        }
                        HStack(spacing: CGFloat.MusicNerd.md) {
                            BorderRadiusDemo(name: "LG", radius: CGFloat.BorderRadius.lg)
                            BorderRadiusDemo(name: "XL", radius: CGFloat.BorderRadius.xl)
                            BorderRadiusDemo(name: "Round", radius: CGFloat.BorderRadius.round)
                        }
                    }
                    .screenPadding()
                }
                
                // Shadow Demo
                MusicNerdSection(title: "Shadow System") {
                    VStack(spacing: CGFloat.MusicNerd.lg) {
                        HStack(spacing: CGFloat.MusicNerd.md) {
                            ShadowDemo(name: "Subtle", shadow: .subtle)
                            ShadowDemo(name: "Soft", shadow: .soft)
                            ShadowDemo(name: "Medium", shadow: .medium)
                        }
                        HStack(spacing: CGFloat.MusicNerd.md) {
                            ShadowDemo(name: "Strong", shadow: .strong)
                            ShadowDemo(name: "Intense", shadow: .intense)
                            Spacer().frame(width: 60) // Placeholder for alignment
                        }
                    }
                    .screenPadding()
                }
            }
        }
    }
}

// MARK: - Preview Helper Views
private struct SpacingDemo: View {
    let name: String
    let value: CGFloat
    
    var body: some View {
        HStack {
            Text(name)
                .musicNerdStyle(.labelMedium())
                .frame(width: 30, alignment: .leading)
            
            Rectangle()
                .fill(Color.MusicNerd.primary)
                .frame(width: value, height: 16)
                .cornerRadius(2)
            
            Text("\(Int(value))pt")
                .musicNerdStyle(.caption())
            
            Spacer()
        }
    }
}

private struct BorderRadiusDemo: View {
    let name: String
    let radius: CGFloat
    
    var body: some View {
        VStack(spacing: CGFloat.MusicNerd.xs) {
            Rectangle()
                .fill(Color.MusicNerd.primary)
                .frame(width: 60, height: 40)
                .cornerRadius(radius)
            
            Text(name)
                .musicNerdStyle(.caption())
        }
    }
}

private struct ShadowDemo: View {
    let name: String
    let shadow: MusicNerdShadow
    
    var body: some View {
        VStack(spacing: CGFloat.MusicNerd.xs) {
            Rectangle()
                .fill(Color.MusicNerd.surface)
                .frame(width: 60, height: 40)
                .cornerRadius(CGFloat.BorderRadius.sm)
                .musicNerdShadow(shadow)
            
            Text(name)
                .musicNerdStyle(.caption())
        }
    }
}