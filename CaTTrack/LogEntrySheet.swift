//
//  LogEntrySheet.swift
//  CaTTrack
//
//  Modal presented when the user taps the "+" tab. Vertical stack:
//
//      Date  ->  Log Type  ->  Time  ->  conditional fields  ->  [Add]
//
//  Conditional fields by log type:
//      .meal      -> kcal, oz served, brand, food type
//      .water     -> ml
//      .restroom  -> (none beyond the always-visible Note field)
//
//  Top-right red X dismisses; swipe-down also dismisses (default
//  behavior for SwiftUI .sheet).
//

import SwiftUI
import SwiftData

struct LogEntrySheet: View {
    
    @EnvironmentObject private var auth: AuthService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // The three top-of-stack fields
    @State private var selectedDate: Date = Date()
    @State private var selectedType: LogType = .meal
    @State private var selectedTime: Date = Date()
    
    // Meal-specific
    @State private var kcalText: String = ""
    @State private var ozServedText: String = ""
    @State private var brand: String = ""
    @State private var foodType: FoodType = .chicken
    
    // Water-specific
    @State private var waterMlText: String = ""
    
    // Always-available note (per spec: restroom uses it most, but
    // any log can carry one).
    @State private var note: String = ""
    
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 1. Date
                    sectionCard(title: "Date", icon: "calendar", tint: .blue) {
                        DatePicker("",
                                   selection: $selectedDate,
                                   displayedComponents: .date)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // 2. Log Type
                    sectionCard(title: "Log Type", icon: "list.bullet", tint: .purple) {
                        Picker("Log Type", selection: $selectedType) {
                            ForEach(LogType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // 3. Time
                    sectionCard(title: "Time", icon: "clock", tint: .indigo) {
                        DatePicker("",
                                   selection: $selectedTime,
                                   displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // 4. Conditional fields driven by selectedType
                    //    (switch over enum — 11 - Enum.swift)
                    Group {
                        switch selectedType {
                        case .meal:    mealFields
                        case .water:   waterFields
                        case .restroom: EmptyView()
                        }
                    }
                    
                    // 5. Note (always visible)
                    sectionCard(title: "Note (optional)",
                                icon: "note.text",
                                tint: .gray) {
                        TextField("Anything unusual? e.g. unusual color",
                                  text: $note,
                                  axis: .vertical)
                            .lineLimit(2...4)
                    }
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                    
                    // 6. Add button (green, full width)
                    Button(action: save) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(16)
                    }
                    .padding(.top, 8)
                    
                    Spacer(minLength: 24)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Red X — top-right dismiss button per spec.
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.title2)
                    }
                }
            }
        }
    }
    
    // MARK: - Conditional Field Groups
    
    private var mealFields: some View {
        VStack(spacing: 16) {
            sectionCard(title: "Calories (kcal, full serving)",
                        icon: "flame.fill",
                        tint: .red) {
                TextField("e.g. 80", text: $kcalText)
                    .keyboardType(.numberPad)
            }
            
            sectionCard(title: "Oz Served",
                        icon: "scalemass",
                        tint: .orange) {
                TextField("e.g. 3.0", text: $ozServedText)
                    .keyboardType(.decimalPad)
            }
            
            sectionCard(title: "Brand",
                        icon: "tag.fill",
                        tint: .yellow) {
                TextField("e.g. Fancy Feast", text: $brand)
                    .textInputAutocapitalization(.words)
            }
            
            sectionCard(title: "Food Type",
                        icon: "fork.knife",
                        tint: .orange) {
                Picker("Food Type", selection: $foodType) {
                    ForEach(FoodType.allCases) { ft in
                        Text(ft.rawValue).tag(ft)
                    }
                }
                .pickerStyle(.menu)
                .tint(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private var waterFields: some View {
        sectionCard(title: "Volume (ml)", icon: "drop.fill", tint: .cyan) {
            TextField("e.g. 50", text: $waterMlText)
                .keyboardType(.numberPad)
        }
    }
    
    // MARK: - Save
    
    private func save() {
        errorMessage = nil
        
        guard let user = auth.currentUser, let pet = user.pets.first else {
            errorMessage = "No active pet on file."
            return
        }
        
        // Compose date + time into a single Date.
        let occurredAt = combine(date: selectedDate, time: selectedTime)
        
        let entry: LogEntry
        switch selectedType {
        case .meal:
            guard let kcal = Int(kcalText), kcal >= 0 else {
                errorMessage = "Please enter a valid kcal number."
                return
            }
            guard let oz = Double(ozServedText), oz > 0 else {
                errorMessage = "Please enter a valid oz amount."
                return
            }
            let trimmedBrand = brand.trimmingCharacters(in: .whitespaces)
            guard !trimmedBrand.isEmpty else {
                errorMessage = "Please enter a brand."
                return
            }
            entry = LogEntry(occurredAt: occurredAt,
                             type: .meal,
                             kcal: kcal,
                             ozServed: oz,
                             brand: trimmedBrand,
                             foodType: foodType,
                             note: trimmedNoteOrNil(),
                             pet: pet)
            
        case .water:
            guard let ml = Int(waterMlText), ml > 0 else {
                errorMessage = "Please enter a valid ml amount."
                return
            }
            entry = LogEntry(occurredAt: occurredAt,
                             type: .water,
                             waterMl: ml,
                             note: trimmedNoteOrNil(),
                             pet: pet)
            
        case .restroom:
            entry = LogEntry(occurredAt: occurredAt,
                             type: .restroom,
                             note: trimmedNoteOrNil(),
                             pet: pet)
        }
        
        modelContext.insert(entry)
        pet.logEntries.append(entry)
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Could not save: \(error.localizedDescription)"
            return
        }
        
        dismiss()
    }
    
    private func trimmedNoteOrNil() -> String? {
        let t = note.trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? nil : t
    }
    
    /// Combines the calendar day from `date` with the hour/minute from `time`.
    private func combine(date: Date, time: Date) -> Date {
        let cal = Calendar.current
        let dayParts = cal.dateComponents([.year, .month, .day], from: date)
        let timeParts = cal.dateComponents([.hour, .minute], from: time)
        var merged = DateComponents()
        merged.year   = dayParts.year
        merged.month  = dayParts.month
        merged.day    = dayParts.day
        merged.hour   = timeParts.hour
        merged.minute = timeParts.minute
        return cal.date(from: merged) ?? Date()
    }
    
    // MARK: - Reusable section card
    //
    // Generic over the inner content (per generics conventions in
    // Swift; not formally introduced in our slides but consistent
    // with the helper-view pattern used elsewhere in the app).
    
    @ViewBuilder
    private func sectionCard<Content: View>(title: String,
                                            icon: String,
                                            tint: Color,
                                            @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .frame(width: 20)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            content()
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
        }
    }
}

#Preview {
    LogEntrySheet()
        .environmentObject(AuthService.previewMock)
        .modelContainer(for: [User.self, Pet.self, PetGoals.self, LogEntry.self, Item.self],
                        inMemory: true)
}
