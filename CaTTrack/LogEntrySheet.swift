//
//  LogEntrySheet.swift
//  CaTTrack
//
//  Modal presented when the user taps the "+" tab. Vertical stack:
//
//      Date  ->  Log Type  ->  Time  ->  conditional fields  ->  [Add]
//
//  Conditional fields by log type:
//      .meal      -> kcal (full serving), full serving oz,
//                    oz served, brand, food type
//      .water     -> ml
//      .restroom  -> (none beyond the always-visible Note field)
//
//  Calorie math: kcal × (ozServed / servingSizeOz). See LogEntry.swift.
//

import SwiftUI
import SwiftData

struct LogEntrySheet: View {
    
    @EnvironmentObject private var auth: AuthService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Top-of-stack
    @State private var selectedDate: Date = Date()
    @State private var selectedType: LogType = .meal
    @State private var selectedTime: Date = Date()
    
    // Meal-specific
    @State private var kcalText: String = ""
    @State private var servingSizeOzText: String = ""
    @State private var ozServedText: String = ""
    @State private var brand: String = ""
    @State private var foodType: FoodType = .chicken
    
    // Water-specific
    @State private var waterMlText: String = ""
    
    // Always-available
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
                    
                    // 6. Add button
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
            // 1) kcal in the full serving
            sectionCard(title: "Calories — Full Serving (kcal)",
                        icon: "flame.fill",
                        tint: .red) {
                TextField("e.g. 300 (kcal in the whole can)", text: $kcalText)
                    .keyboardType(.numberPad)
            }
            
            // 2) Full serving size in oz
            sectionCard(title: "Full Serving Size (oz)",
                        icon: "shippingbox.fill",
                        tint: .brown) {
                TextField("e.g. 5.0 (oz in the whole can)",
                          text: $servingSizeOzText)
                    .keyboardType(.decimalPad)
            }
            
            // 3) Amount actually served
            sectionCard(title: "Oz Served",
                        icon: "scalemass",
                        tint: .orange) {
                TextField("e.g. 3.0 (oz cat actually ate)",
                          text: $ozServedText)
                    .keyboardType(.decimalPad)
            }
            
            // 4) Brand
            sectionCard(title: "Brand",
                        icon: "tag.fill",
                        tint: .yellow) {
                TextField("e.g. Fancy Feast", text: $brand)
                    .textInputAutocapitalization(.words)
            }
            
            // 5) Food Type
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
            
            // Live preview of the calorie math so the user can see
            // what will actually land on the dashboard.
            if let preview = caloriesPreview() {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Calories consumed: \(preview) kcal")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var waterFields: some View {
        sectionCard(title: "Volume (ml)", icon: "drop.fill", tint: .cyan) {
            TextField("e.g. 50", text: $waterMlText)
                .keyboardType(.numberPad)
        }
    }
    
    /// Returns the previewed kcal consumed if the user has entered
    /// enough valid data. Used purely for the live preview hint.
    private func caloriesPreview() -> Int? {
        guard let total = Int(kcalText), total > 0,
              let serving = Double(servingSizeOzText), serving > 0,
              let served = Double(ozServedText), served > 0
        else {
            return nil
        }
        let ratio = min(served / serving, 1.0)
        return Int((Double(total) * ratio).rounded())
    }
    
    // MARK: - Save
    
    private func save() {
        errorMessage = nil
        
        guard let user = auth.currentUser, let pet = user.pets.first else {
            errorMessage = "No active pet on file."
            return
        }
        
        let occurredAt = combine(date: selectedDate, time: selectedTime)
        
        let entry: LogEntry
        switch selectedType {
        case .meal:
            // Full validation chain — guard / let pattern from
            // 3 - ControlFlow.swift.
            guard let kcal = Int(kcalText), kcal > 0 else {
                errorMessage = "Please enter a valid kcal number for the full serving."
                return
            }
            guard let serving = Double(servingSizeOzText), serving > 0 else {
                errorMessage = "Please enter a valid full-serving size in oz."
                return
            }
            guard let oz = Double(ozServedText), oz > 0 else {
                errorMessage = "Please enter a valid oz amount served."
                return
            }
            guard oz <= serving else {
                errorMessage = "Oz served (\(oz)) cannot exceed the full serving size (\(serving))."
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
                             servingSizeOz: serving,
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
