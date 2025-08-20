//
//  HistoryFilterView.swift
//  MusicNerd
//
//  Created by Claude on 8/10/25.
//

import SwiftUI

struct HistoryFilterView: View {
    @Binding var filterCriteria: FilterCriteria
    @Binding var isPresented: Bool
    
    @State private var tempCriteria: FilterCriteria
    @State private var showingDatePicker = false
    @State private var datePickerType: DatePickerType = .start
    
    init(filterCriteria: Binding<FilterCriteria>, isPresented: Binding<Bool>) {
        self._filterCriteria = filterCriteria
        self._isPresented = isPresented
        self._tempCriteria = State(initialValue: filterCriteria.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            List {
                // Enrichment Status Filter Section
                Section {
                    ForEach(EnrichmentStatusFilter.allCases, id: \.rawValue) { status in
                        HStack {
                            Text(status.rawValue)
                                .musicNerdStyle(.bodyLarge())
                            
                            Spacer()
                            
                            if tempCriteria.enrichmentStatus == status {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.MusicNerd.primary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            tempCriteria.enrichmentStatus = status
                        }
                    }
                } header: {
                    Text("Enrichment Status")
                        .musicNerdStyle(.titleSmall(color: Color.MusicNerd.textSecondary))
                }
                
                // Date Range Filter Section
                Section {
                    // Quick date filters
                    ForEach(QuickDateFilter.allCases, id: \.rawValue) { quickFilter in
                        HStack {
                            Text(quickFilter.displayName)
                                .musicNerdStyle(.bodyLarge())
                            
                            Spacer()
                            
                            if isQuickFilterActive(quickFilter) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.MusicNerd.primary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            applyQuickDateFilter(quickFilter)
                        }
                    }
                    
                    // Custom date range
                    VStack(alignment: .leading, spacing: CGFloat.MusicNerd.sm) {
                        HStack {
                            Text("Custom Range")
                                .musicNerdStyle(.bodyLarge())
                            
                            Spacer()
                            
                            if tempCriteria.startDate != nil || tempCriteria.endDate != nil {
                                if !isQuickFilterActive(.all) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Color.MusicNerd.primary)
                                }
                            }
                        }
                        
                        HStack {
                            Button(action: {
                                datePickerType = .start
                                showingDatePicker = true
                            }) {
                                Text(tempCriteria.startDate?.formatted(date: .abbreviated, time: .omitted) ?? "From Date")
                                    .musicNerdStyle(.bodyMedium(color: tempCriteria.startDate != nil ? Color.MusicNerd.text : Color.MusicNerd.textSecondary))
                                    .padding(.horizontal, CGFloat.MusicNerd.sm)
                                    .padding(.vertical, CGFloat.MusicNerd.xs)
                                    .background(Color.MusicNerd.surface)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text("to")
                                .musicNerdStyle(.bodySmall(color: Color.MusicNerd.textSecondary))
                            
                            Button(action: {
                                datePickerType = .end
                                showingDatePicker = true
                            }) {
                                Text(tempCriteria.endDate?.formatted(date: .abbreviated, time: .omitted) ?? "To Date")
                                    .musicNerdStyle(.bodyMedium(color: tempCriteria.endDate != nil ? Color.MusicNerd.text : Color.MusicNerd.textSecondary))
                                    .padding(.horizontal, CGFloat.MusicNerd.sm)
                                    .padding(.vertical, CGFloat.MusicNerd.xs)
                                    .background(Color.MusicNerd.surface)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                        }
                    }
                } header: {
                    Text("Date Range")
                        .musicNerdStyle(.titleSmall(color: Color.MusicNerd.textSecondary))
                }
            }
            .listStyle(InsetGroupedListStyle())
            .background(Color.MusicNerd.background)
            .navigationTitle("Filter History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        tempCriteria = FilterCriteria()
                    }
                    .foregroundColor(Color.MusicNerd.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        filterCriteria = tempCriteria
                        isPresented = false
                    }
                    .foregroundColor(Color.MusicNerd.primary)
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            NavigationView {
                DatePicker(
                    datePickerType == .start ? "Start Date" : "End Date",
                    selection: datePickerType == .start ? 
                        Binding(
                            get: { tempCriteria.startDate ?? Date() },
                            set: { tempCriteria.startDate = $0 }
                        ) :
                        Binding(
                            get: { tempCriteria.endDate ?? Date() },
                            set: { tempCriteria.endDate = $0 }
                        ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle(datePickerType == .start ? "Start Date" : "End Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingDatePicker = false
                        }
                        .foregroundColor(Color.MusicNerd.primary)
                        .fontWeight(.semibold)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func isQuickFilterActive(_ quickFilter: QuickDateFilter) -> Bool {
        let (start, end) = quickFilter.dateRange
        return tempCriteria.startDate == start && tempCriteria.endDate == end
    }
    
    private func applyQuickDateFilter(_ quickFilter: QuickDateFilter) {
        let (start, end) = quickFilter.dateRange
        tempCriteria.startDate = start
        tempCriteria.endDate = end
    }
}

// MARK: - Supporting Types

enum DatePickerType {
    case start
    case end
}

enum QuickDateFilter: String, CaseIterable {
    case all = "all"
    case today = "today"
    case thisWeek = "thisWeek"
    case thisMonth = "thisMonth"
    case last7Days = "last7Days"
    case last30Days = "last30Days"
    
    var displayName: String {
        switch self {
        case .all: return "All Time"
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .last7Days: return "Last 7 Days"
        case .last30Days: return "Last 30 Days"
        }
    }
    
    var dateRange: (start: Date?, end: Date?) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .all:
            return (nil, nil)
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)
            return (startOfDay, endOfDay)
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start
            let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.end
            return (startOfWeek, endOfWeek)
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start
            let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end
            return (startOfMonth, endOfMonth)
        case .last7Days:
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)
            return (sevenDaysAgo, now)
        case .last30Days:
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)
            return (thirtyDaysAgo, now)
        }
    }
}

#Preview {
    HistoryFilterView(
        filterCriteria: .constant(FilterCriteria()),
        isPresented: .constant(true)
    )
}
