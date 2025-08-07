import SwiftUI

struct CacheExpirationPickerView: View {
    let selectedHours: Double
    let onSelection: (Double) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(AppSettings.cacheExpirationOptions, id: \.self) { hours in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(AppSettings.formatCacheExpiration(hours))
                                    .musicNerdStyle(.bodyLarge())
                                
                                if hours == 1 {
                                    Text("Frequent updates, higher data usage")
                                        .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
                                } else if hours == 24 {
                                    Text("Good balance (recommended)")
                                        .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
                                } else if hours == 168 {
                                    Text("Lowest data usage")
                                        .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
                                } else if hours >= 48 {
                                    Text("Minimal network requests")
                                        .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
                                }
                            }
                            
                            Spacer()
                            
                            if hours == selectedHours {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.MusicNerd.primary)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelection(hours)
                        }
                        .accessibilityIdentifier("cache-expiration-option-\(Int(hours))")
                    }
                } header: {
                    Text("Cache Duration")
                        .musicNerdStyle(.titleSmall(color: Color.MusicNerd.textSecondary))
                } footer: {
                    Text("Cached artist info reduces network usage and speeds up the app. Longer durations save data but may show outdated information.")
                        .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
                }
            }
            .listStyle(InsetGroupedListStyle())
            .background(Color.MusicNerd.background)
            .navigationTitle("Cache Duration")
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
    CacheExpirationPickerView(
        selectedHours: 24.0,
        onSelection: { _ in }
    )
}