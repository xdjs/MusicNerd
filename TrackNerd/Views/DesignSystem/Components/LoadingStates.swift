import SwiftUI

// MARK: - Loading Spinner
struct MusicNerdLoadingSpinner: View {
    var size: SpinnerSize = .medium
    var color: Color = Color.MusicNerd.primary
    
    enum SpinnerSize {
        case small
        case medium
        case large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 32
            case .large: return 48
            }
        }
        
        var lineWidth: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 3
            case .large: return 4
            }
        }
    }
    
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [color.opacity(0.1), color]),
                    center: .center
                ),
                style: StrokeStyle(lineWidth: size.lineWidth, lineCap: .round)
            )
            .frame(width: size.dimension, height: size.dimension)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1.0).repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Waveform Loading Animation
struct WaveformLoading: View {
    let barCount: Int = 5
    @State private var animatingBars: [Bool]
    
    init() {
        _animatingBars = State(initialValue: Array(repeating: false, count: barCount))
    }
    
    var body: some View {
        HStack(spacing: CGFloat.MusicNerd.xs) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.MusicNerd.waveformActive)
                    .frame(width: 4, height: animatingBars[index] ? 24 : 8)
                    .animation(
                        Animation
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                        value: animatingBars[index]
                    )
            }
        }
        .onAppear {
            for index in 0..<barCount {
                animatingBars[index] = true
            }
        }
    }
}

// MARK: - Pulse Animation
struct PulseAnimation: View {
    var color: Color = Color.MusicNerd.primary
    var size: CGFloat = 80
    
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            // Outer pulse
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: size, height: size)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0.0 : 0.4)
            
            // Middle pulse
            Circle()
                .fill(color.opacity(0.4))
                .frame(width: size * 0.7, height: size * 0.7)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .opacity(isPulsing ? 0.0 : 0.6)
            
            // Inner circle
            Circle()
                .fill(color)
                .frame(width: size * 0.5, height: size * 0.5)
                .scaleEffect(isPulsing ? 1.1 : 1.0)
        }
        .animation(
            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false),
            value: isPulsing
        )
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Loading States Container
struct LoadingStateView: View {
    let message: String
    var loadingType: LoadingType = .spinner
    var showMessage: Bool = true
    
    enum LoadingType {
        case spinner
        case waveform
        case pulse
    }
    
    var body: some View {
        VStack(spacing: CGFloat.MusicNerd.md) {
            Group {
                switch loadingType {
                case .spinner:
                    MusicNerdLoadingSpinner(size: .large)
                case .waveform:
                    WaveformLoading()
                case .pulse:
                    PulseAnimation()
                        .frame(width: 80, height: 80)
                }
            }
            
            if showMessage {
                Text(message)
                    .musicNerdStyle(.bodyMedium(color: Color.MusicNerd.textSecondary))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.MusicNerd.background.opacity(0.9))
    }
}

// MARK: - Skeleton Loading
struct SkeletonView: View {
    var width: CGFloat = 100
    var height: CGFloat = 16
    var cornerRadius: CGFloat = CGFloat.BorderRadius.xs
    
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.MusicNerd.accent.opacity(0.3),
                        Color.MusicNerd.accent.opacity(0.1),
                        Color.MusicNerd.accent.opacity(0.3)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .offset(x: isAnimating ? width : -width)
            .animation(
                Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
            .clipped()
    }
}

// MARK: - Progress Indicator
struct MusicNerdProgressView: View {
    let progress: Double // 0.0 to 1.0
    var height: CGFloat = 4
    var backgroundColor: Color = Color.MusicNerd.accent.opacity(0.3)
    var foregroundColor: Color = Color.MusicNerd.primary
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(backgroundColor)
                    .frame(height: height)
                    .cornerRadius(height / 2)
                
                Rectangle()
                    .fill(foregroundColor)
                    .frame(width: geometry.size.width * CGFloat(progress), height: height)
                    .cornerRadius(height / 2)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Preview
#Preview("Loading States") {
    ScrollView {
        VStack(spacing: CGFloat.MusicNerd.xl) {
            // Spinners
            VStack(spacing: CGFloat.MusicNerd.md) {
                Text("Loading Spinners")
                    .musicNerdStyle(.headlineMedium())
                
                HStack(spacing: CGFloat.MusicNerd.lg) {
                    VStack {
                        MusicNerdLoadingSpinner(size: .small)
                        Text("Small").musicNerdStyle(.caption())
                    }
                    VStack {
                        MusicNerdLoadingSpinner(size: .medium)
                        Text("Medium").musicNerdStyle(.caption())
                    }
                    VStack {
                        MusicNerdLoadingSpinner(size: .large)
                        Text("Large").musicNerdStyle(.caption())
                    }
                }
            }
            
            Divider()
            
            // Waveform and Pulse
            VStack(spacing: CGFloat.MusicNerd.md) {
                Text("Audio Loading States")
                    .musicNerdStyle(.headlineMedium())
                
                VStack(spacing: CGFloat.MusicNerd.lg) {
                    VStack {
                        WaveformLoading()
                        Text("Listening...").musicNerdStyle(.caption())
                    }
                    
                    VStack {
                        PulseAnimation(size: 60)
                        Text("Processing...").musicNerdStyle(.caption())
                    }
                }
            }
            
            Divider()
            
            // Skeleton Loading
            VStack(spacing: CGFloat.MusicNerd.md) {
                Text("Skeleton Loading")
                    .musicNerdStyle(.headlineMedium())
                
                VStack(alignment: .leading, spacing: CGFloat.MusicNerd.sm) {
                    SkeletonView(width: 200, height: 20)
                    SkeletonView(width: 150, height: 16)
                    SkeletonView(width: 100, height: 14)
                }
            }
            
            Divider()
            
            // Progress View
            VStack(spacing: CGFloat.MusicNerd.md) {
                Text("Progress Indicator")
                    .musicNerdStyle(.headlineMedium())
                
                VStack(spacing: CGFloat.MusicNerd.sm) {
                    MusicNerdProgressView(progress: 0.3)
                    MusicNerdProgressView(progress: 0.6)
                    MusicNerdProgressView(progress: 0.9)
                }
            }
        }
        .padding()
    }
    .background(Color.MusicNerd.background)
}