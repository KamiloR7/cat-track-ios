//
//  DailyTrendChart.swift
//  CaTTrack
//
//  Daily trend line chart for the dashboard. Three switchable
//  series — Calories, Water, Restroom — with a time-range cycler
//  that toggles 7 → 14 → 30 day windows. Each x-step is exactly
//  one day, so a 30-day range packs 30 nodes into the same chart
//  width as a 7-day range (smoother visual line, same axis count).
//
//  Built on Apple's Charts framework (iOS 16+, per 12 SwiftUI.pdf
//  era — Apple-native, no third party dependency).
//
//  Series styling:
//    - Calories : solid red,   dashed faint red goal line
//    - Water    : solid blue,  dashed lighter blue goal line
//    - Restroom : solid green, no goal line (visits are uncapped)
//

import SwiftUI
import Charts
import SwiftData

// MARK: - Series & Range

enum TrendSeries: String, CaseIterable, Identifiable {
    case calories = "Calories"
    case water    = "Water"
    case restroom = "Restroom"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .calories: return "flame.fill"
        case .water:    return "drop.fill"
        case .restroom: return "toilet.fill"
        }
    }
    
    var lineColor: Color {
        switch self {
        case .calories: return .red
        case .water:    return .blue
        case .restroom: return .green
        }
    }
    
    var goalLineColor: Color {
        // Faint version of the line color for the dashed goal.
        switch self {
        case .calories: return Color.red.opacity(0.35)
        case .water:    return Color.blue.opacity(0.35)
        case .restroom: return .clear   // no goal line for restroom
        }
    }
    
    var yAxisLabel: String {
        switch self {
        case .calories: return "kcal"
        case .water:    return "ml"
        case .restroom: return "visits"
        }
    }
}

enum TrendRange: Int, CaseIterable, Identifiable {
    case days7  = 7
    case days14 = 14
    case days30 = 30
    
    var id: Int { rawValue }
    
    /// Cycle to the next range. 7 → 14 → 30 → 7.
    var next: TrendRange {
        switch self {
        case .days7:  return .days14
        case .days14: return .days30
        case .days30: return .days7
        }
    }
}

// MARK: - Per-day data point

private struct DailyPoint: Identifiable {
    let id = UUID()
    let day: Date    // start-of-day
    let value: Double
}

// MARK: - DailyTrendChart

struct DailyTrendChart: View {
    
    @EnvironmentObject private var auth: AuthService
    
    /// Pulls the last 30 days of LogEntry rows for any pet. We
    /// over-fetch (always 30) so changing the range picker is just
    /// a slice operation rather than re-issuing the query.
    @Query private var recentEntries: [LogEntry]
    
    @State private var series: TrendSeries = .calories
    @State private var range: TrendRange = .days7
    
    init() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let thirtyDaysAgo = cal.date(byAdding: .day, value: -29, to: today) ?? today
        
        _recentEntries = Query(
            filter: #Predicate<LogEntry> { entry in
                entry.occurredAt >= thirtyDaysAgo
            },
            sort: \LogEntry.occurredAt,
            order: .forward
        )
    }
    
    private var currentPet: Pet? {
        auth.currentUser?.pets.first
    }
    
    /// Entries narrowed to the active pet only.
    private var petEntries: [LogEntry] {
        guard let pet = currentPet else { return [] }
        let petID = pet.persistentModelID
        return recentEntries.filter { $0.pet?.persistentModelID == petID }
    }
    
    // MARK: - View
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Header: dropdown on the left, title on the right
            HStack(spacing: 12) {
                seriesPicker
                
                Spacer()
                
                Text(series.rawValue)
                    .font(.headline)
            }
            .padding(.horizontal, 4)
            
            // Chart body
            chartView
                .frame(height: 200)
            
            // Bottom row: y-axis unit on the left, range cycler on the right
            HStack {
                Text(series.yAxisLabel)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                Spacer()
                rangeCycler
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Header subviews
    
    /// Top-left dropdown. Default icon = current series icon, with a
    /// chevron next to it. Tapping reveals the other two series.
    private var seriesPicker: some View {
        Menu {
            ForEach(TrendSeries.allCases) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        series = option
                    }
                } label: {
                    Label(option.rawValue, systemImage: option.icon)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: series.icon)
                    .foregroundStyle(series.lineColor)
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(series.lineColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    /// Bottom-right tappable number. Cycles 7 → 14 → 30 on tap.
    private var rangeCycler: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                range = range.next
            }
        } label: {
            HStack(spacing: 4) {
                Text("\(range.rawValue)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("days")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Chart
    
    private var chartView: some View {
        let points = dailyPoints
        let goal = currentGoal
        
        return Chart {
            // Goal line — dashed faint, only for series with a goal
            if let goal = goal, series != .restroom {
                RuleMark(y: .value("Goal", goal))
                    .lineStyle(StrokeStyle(lineWidth: 1.5,
                                           dash: [5, 4]))
                    .foregroundStyle(series.goalLineColor)
            }
            
            // Solid daily line
            ForEach(points) { point in
                LineMark(
                    x: .value("Day", point.day),
                    y: .value(series.yAxisLabel, point.value)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(series.lineColor)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                
                // Small dot per node so daily values are still visible
                PointMark(
                    x: .value("Day", point.day),
                    y: .value(series.yAxisLabel, point.value)
                )
                .foregroundStyle(series.lineColor)
                .symbolSize(20)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartXAxis {
            // Show abbreviated weekday for 7d, day-of-month for 14d/30d.
            AxisMarks(values: .stride(by: .day, count: xAxisStride)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: xAxisFormat, centered: false)
            }
        }
    }
    
    // MARK: - Aggregation
    
    /// Builds an array of (day, value) tuples spanning the selected
    /// range. Days with no entries get 0 so the line continues through
    /// gaps rather than disconnecting.
    private var dailyPoints: [DailyPoint] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dayCount = range.rawValue
        
        // Build the day axis first — 7, 14, or 30 day-aligned bins
        // ending at today.
        let days: [Date] = (0..<dayCount).reversed().compactMap { offset in
            cal.date(byAdding: .day, value: -offset, to: today)
        }
        
        // Bucket entries by start-of-day.
        var buckets: [Date: Double] = [:]
        for entry in petEntries {
            let key = cal.startOfDay(for: entry.occurredAt)
            let contribution: Double
            switch series {
            case .calories:
                contribution = entry.type == .meal
                    ? Double(entry.caloriesConsumed)
                    : 0
            case .water:
                contribution = entry.type == .water
                    ? Double(entry.waterMl ?? 0)
                    : 0
            case .restroom:
                contribution = entry.type == .restroom ? 1 : 0
            }
            if contribution > 0 {
                buckets[key, default: 0] += contribution
            }
        }
        
        return days.map { day in
            DailyPoint(day: day, value: buckets[day] ?? 0)
        }
    }
    
    /// The dashed reference line value, pulled from PetGoals.
    /// Returns nil for restroom (no goal exists).
    private var currentGoal: Double? {
        guard let g = currentPet?.goals else { return nil }
        switch series {
        case .calories: return Double(g.targetCaloriesPerDay)
        case .water:    return Double(g.targetWaterMlPerDay)
        case .restroom: return nil
        }
    }
    
    // MARK: - Axis tuning
    
    /// Show every day for 7, every 2 days for 14, every 5 for 30.
    /// Keeps the axis labels readable at every range without crowding.
    private var xAxisStride: Int {
        switch range {
        case .days7:  return 1
        case .days14: return 2
        case .days30: return 5
        }
    }
    
    private var xAxisFormat: Date.FormatStyle {
        switch range {
        case .days7:
            return .dateTime.weekday(.abbreviated)
        case .days14, .days30:
            return .dateTime.month(.abbreviated).day()
        }
    }
}

#Preview {
    DailyTrendChart()
        .padding()
        .environmentObject(AuthService.previewMock)
        .modelContainer(for: [User.self, Pet.self, PetGoals.self, LogEntry.self, Item.self],
                        inMemory: true)
}
