//
//  CalendarTabView.swift
//  CaTTrack
//
//  Calendar tab. Shows a monthly grid; tapping a day reveals an
//  Apple-Calendar-style stack of three "event" rows:
//
//      Meals: N
//      Water: N
//      Toilet: N
//
//  Each row is a DisclosureGroup — expanding it reveals every
//  underlying LogEntry (with log time and any type-specific fields).
//

import SwiftUI
import SwiftData

struct CalendarTabView: View {
    
    @EnvironmentObject private var auth: AuthService
    
    // SwiftData @Query — declarative read of LogEntry rows. Sorted
    // by occurredAt so groupings preserve chronological order.
    @Query(sort: \LogEntry.occurredAt, order: .forward)
    private var allEntries: [LogEntry]
    
    @State private var visibleMonth: Date = Date()
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())
    
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    
                    monthHeader
                    
                    weekdayHeader
                    
                    monthGrid
                    
                    Divider().padding(.vertical, 4)
                    
                    selectedDayPanel
                    
                    Spacer(minLength: 24)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Active Pet's entries
    
    private var petEntries: [LogEntry] {
        guard let pet = auth.currentUser?.pets.first else { return [] }
        return allEntries.filter { $0.pet?.persistentModelID == pet.persistentModelID }
    }
    
    // MARK: - Month Header (prev / month-name / next)
    
    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            
            Spacer()
            
            Text(monthTitle)
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal, 8)
    }
    
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"  // e.g. "April 2026"
        return formatter.string(from: visibleMonth)
    }
    
    private func shiftMonth(by months: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: months, to: visibleMonth) {
            visibleMonth = newMonth
        }
    }
    
    // MARK: - Weekday Header (Sun Mon Tue ...)
    
    private var weekdayHeader: some View {
        HStack {
            ForEach(calendar.shortStandaloneWeekdaySymbols, id: \.self) { sym in
                Text(sym)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Month Grid
    
    private var monthGrid: some View {
        let days = generateMonthDays(for: visibleMonth)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(days, id: \.self) { day in
                dayCell(for: day)
            }
        }
    }
    
    @ViewBuilder
    private func dayCell(for day: Date?) -> some View {
        if let day {
            let isInMonth = calendar.isDate(day, equalTo: visibleMonth, toGranularity: .month)
            let isSelected = calendar.isDate(day, inSameDayAs: selectedDay)
            let isToday = calendar.isDateInToday(day)
            let counts = countsFor(day: day)
            
            // Resolve to a concrete Color in both branches so the ternary
            // returns one uniform type. Using HierarchicalShapeStyle's
            // .primary / .secondary inside a ternary — and then calling
            // .opacity on one branch only — fails to type-check.
            let dayNumberColor: Color = isInMonth
                ? Color.primary
                : Color.secondary.opacity(0.5)
            
            Button {
                selectedDay = calendar.startOfDay(for: day)
            } label: {
                VStack(spacing: 2) {
                    Text("\(calendar.component(.day, from: day))")
                        .font(.subheadline)
                        .fontWeight(isToday ? .bold : .regular)
                        .foregroundStyle(dayNumberColor)
                    
                    // Tiny dots indicating activity
                    HStack(spacing: 2) {
                        if counts.meals > 0    { dot(.orange) }
                        if counts.water > 0    { dot(.cyan)   }
                        if counts.restroom > 0 { dot(.green)  }
                    }
                    .frame(height: 6)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue.opacity(0.18) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isToday ? Color.blue : Color.clear, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        } else {
            Color.clear.frame(minHeight: 44)
        }
    }
    
    private func dot(_ color: Color) -> some View {
        Circle().fill(color).frame(width: 4, height: 4)
    }
    
    /// Returns 42 cells (6 rows × 7 cols) with leading/trailing nils
    /// so the first-of-month aligns under the correct weekday column.
    private func generateMonthDays(for month: Date) -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else { return [] }
        
        let leadingBlanks = firstWeekday - calendar.firstWeekday
        let blanksCount = leadingBlanks < 0 ? leadingBlanks + 7 : leadingBlanks
        
        let dayCount = calendar.range(of: .day, in: .month, for: month)?.count ?? 30
        
        var cells: [Date?] = Array(repeating: nil, count: blanksCount)
        for d in 0..<dayCount {
            if let date = calendar.date(byAdding: .day, value: d, to: monthInterval.start) {
                cells.append(date)
            }
        }
        // Pad to a multiple of 7.
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }
    
    // MARK: - Counts per day
    
    private struct DayCounts {
        var meals: Int = 0
        var water: Int = 0
        var restroom: Int = 0
    }
    
    private func entriesFor(day: Date) -> [LogEntry] {
        petEntries.filter { calendar.isDate($0.occurredAt, inSameDayAs: day) }
    }
    
    private func countsFor(day: Date) -> DayCounts {
        var c = DayCounts()
        for e in entriesFor(day: day) {
            switch e.type {
            case .meal:     c.meals    += 1
            case .water:    c.water    += 1
            case .restroom: c.restroom += 1
            }
        }
        return c
    }
    
    // MARK: - Selected Day Panel (Apple-Calendar-style events)
    
    private var selectedDayPanel: some View {
        let entries = entriesFor(day: selectedDay)
        let mealEntries     = entries.filter { $0.type == .meal }
        let waterEntries    = entries.filter { $0.type == .water }
        let restroomEntries = entries.filter { $0.type == .restroom }
        
        return VStack(alignment: .leading, spacing: 12) {
            Text(longDateString(selectedDay))
                .font(.headline)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                EventRow(label: "Meals",
                         count: mealEntries.count,
                         icon: "fork.knife",
                         tint: .orange,
                         entries: mealEntries)
                Divider().padding(.leading, 44)
                EventRow(label: "Water",
                         count: waterEntries.count,
                         icon: "drop.fill",
                         tint: .cyan,
                         entries: waterEntries)
                Divider().padding(.leading, 44)
                EventRow(label: "Toilet",
                         count: restroomEntries.count,
                         icon: "toilet.fill",
                         tint: .green,
                         entries: restroomEntries)
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    private func longDateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .none
        return f.string(from: date)
    }
}

// MARK: - EventRow (DisclosureGroup row)

private struct EventRow: View {
    let label: String
    let count: Int
    let icon: String
    let tint: Color
    let entries: [LogEntry]
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(spacing: 8) {
                ForEach(entries) { entry in
                    LogEntryDetailRow(entry: entry, tint: tint)
                }
                if entries.isEmpty {
                    Text("No entries.")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.top, 4)
            .padding(.leading, 32)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .frame(width: 24)
                Text("\(label): \(count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal)
        .disabled(count == 0)
    }
}

// MARK: - Detail row for a single LogEntry inside the expanded section

private struct LogEntryDetailRow: View {
    let entry: LogEntry
    let tint: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                Text(timeString(entry.occurredAt))
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                Spacer()
            }
            
            switch entry.type {
            case .meal:
                if let kcal = entry.kcal {
                    Text("Calories: \(kcal) kcal")
                        .font(.subheadline)
                }
                if let oz = entry.ozServed {
                    Text(String(format: "Served: %.1f oz", oz))
                        .font(.subheadline)
                }
                if let brand = entry.brand, !brand.isEmpty {
                    Text("Brand: \(brand)")
                        .font(.subheadline)
                }
                if let ft = entry.foodType {
                    Text("Food: \(ft.rawValue)")
                        .font(.subheadline)
                }
                
            case .water:
                if let ml = entry.waterMl {
                    Text("Volume: \(ml) ml")
                        .font(.subheadline)
                }
                
            case .restroom:
                Text("Restroom visit")
                    .font(.subheadline)
            }
            
            if let note = entry.note, !note.isEmpty {
                Text("Note: \(note)")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .padding(.top, 2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08))
        .cornerRadius(10)
    }
    
    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}

#Preview {
    CalendarTabView()
        .environmentObject(AuthService.previewMock)
        .modelContainer(for: [User.self, Pet.self, PetGoals.self, LogEntry.self, Item.self],
                        inMemory: true)
}
