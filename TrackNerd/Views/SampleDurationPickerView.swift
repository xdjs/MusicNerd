import SwiftUI

struct SampleDurationPickerView: View {
    let selectedDuration: TimeInterval
    let onSelection: (TimeInterval) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(AppSettings.sampleDurationOptions, id: \.self) { duration in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(AppSettings.formatDuration(duration))
                                    .musicNerdStyle(.bodyLarge())
                                
                                if duration == 3 {
                                    Text("Quick recognition (recommended)")
                                        .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
                                } else if duration == 20 {
                                    Text("More accurate for challenging audio")
                                        .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
                                } else if duration >= 10 {
                                    Text("Better accuracy for noisy environments")
                                        .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
                                }
                            }
                            
                            Spacer()
                            
                            if duration == selectedDuration {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.MusicNerd.primary)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelection(duration)
                        }
                        .accessibilityIdentifier("duration-option-\(Int(duration))")
                    }
                } header: {
                    Text("Sample Duration")
                        .musicNerdStyle(.titleSmall(color: Color.MusicNerd.textSecondary))
                } footer: {
                    Text("Longer durations may provide more accurate recognition but take more time. 3 seconds is usually sufficient for most music.")
                        .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
                }
            }
            .listStyle(InsetGroupedListStyle())
            .background(Color.MusicNerd.background)
            .navigationTitle("Sample Duration")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.MusicNerd.primary)
                    .accessibilityIdentifier("cancel-button")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    SampleDurationPickerView(
        selectedDuration: 3.0,
        onSelection: { _ in }
    )
}