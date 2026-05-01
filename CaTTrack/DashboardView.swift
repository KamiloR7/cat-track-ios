//
//  DashboardView.swift
//  CaTTrack
//
//  Home tab. Live data:
//    - Cat profile pulls from the active Pet.
//    - Daily Goals & Stats pulls from PetGoals (targets) and from
//      today's LogEntry rows (current values).
//    - Body Condition Score is computed from current weight + breed
//      via BodyConditionEstimator.
//    - DailyTrendChart visualizes calories / water / restroom over
//      the last 7, 14, or 30 days.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    
    @EnvironmentObject private var auth: AuthService
    
    @State private var isGoalsExpanded: Bool = true
    @State private var isShowingBCSDetail: Bool = false
    
    @Query private var todaysEntries: [LogEntry]
    
    init() {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: Date())
        let startOfTomorrow = cal.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday
        
        _todaysEntries = Query(
            filter: #Predicate<LogEntry> { entry in
                entry.occurredAt >= startOfToday && entry.occurredAt < startOfTomorrow
            },
            sort: \LogEntry.occurredAt,
            order: .forward
        )
    }
    
    private var currentPet: Pet? {
        auth.currentUser?.pets.first
    }
    
    private var petEntriesToday: [LogEntry] {
        guard let pet = currentPet else { return [] }
        let petID = pet.persistentModelID
        return todaysEntries.filter { $0.pet?.persistentModelID == petID }
    }
    
    // MARK: - Aggregates
    
    private var caloriesToday: Int {
        petEntriesToday
            .filter { $0.type == .meal }
            .reduce(0) { $0 + $1.caloriesConsumed }
    }
    
    private var waterMlToday: Int {
        petEntriesToday
            .filter { $0.type == .water }
            .reduce(0) { $0 + ($1.waterMl ?? 0) }
    }
    
    private var restroomVisitsToday: Int {
        petEntriesToday.filter { $0.type == .restroom }.count
    }
    
    // MARK: - Body Condition
    
    private var bodyCondition: BodyCondition? {
        guard let pet = currentPet else { return nil }
        return BodyConditionEstimator.evaluate(
            weightKg: pet.weightKg,
            breed: pet.breedEnum
        )
    }
    
    // MARK: - View
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Cat Profile Card
                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            PetAvatarView(breed: currentPet?.breedEnum, size: 84)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(currentPet?.name ?? "—")
                                    .font(.title2)
                                    .bold()
                                Text(petSubtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                        
                        HStack(spacing: 24) {
                            statBadge(icon: "scalemass.fill",
                                      label: "Weight",
                                      value: weightDisplay,
                                      tint: .orange)
                            
                            Button {
                                isShowingBCSDetail = true
                            } label: {
                                bcsStatBadge
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    
                    // Daily Goals Section (Minimizable)
                    VStack(spacing: 0) {
                        Button {
                            withAnimation(.spring()) {
                                isGoalsExpanded.toggle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "target")
                                    .foregroundStyle(.blue)
                                Text("Daily Goals & Stats")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: isGoalsExpanded ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(Color.secondary)
                            }
                            .padding()
                        }
                        .buttonStyle(.plain)
                        
                        if isGoalsExpanded {
                            VStack(spacing: 16) {
                                ProgressGoalCard(
                                    icon: "flame.fill",
                                    title: "Calories",
                                    currentText: "\(caloriesToday)",
                                    goalText: caloriesGoalText,
                                    progress: caloriesProgress,
                                    color: .red
                                )
                                
                                ProgressGoalCard(
                                    icon: "drop.fill",
                                    title: "Water",
                                    currentText: "\(waterMlToday) ml",
                                    goalText: waterGoalText,
                                    progress: waterProgress,
                                    color: .cyan
                                )
                                
                                CountGoalCard(
                                    icon: "toilet.fill",
                                    title: "Restroom",
                                    count: restroomVisitsToday,
                                    color: .green
                                )
                            }
                            .padding()
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    
                    // Daily trend chart
                    DailyTrendChart()
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out") { auth.logout() }
                        .foregroundStyle(.red)
                }
            }
            .sheet(isPresented: $isShowingBCSDetail) {
                if let bc = bodyCondition, let pet = currentPet {
                    BCSDetailSheet(
                        bodyCondition: bc,
                        petName: pet.name,
                        breedName: pet.breedEnum.rawValue
                    )
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
        }
    }
    
    // MARK: - BCS Stat Badge
    
    private var bcsStatBadge: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(bcsTintColor.opacity(0.18))
                    .frame(width: 30, height: 30)
                if let bc = bodyCondition {
                    Text("\(bc.score)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(bcsTintColor)
                } else {
                    Text("--")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("BCS (est.)")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                Text(bcsCategoryText)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var bcsTintColor: Color {
        guard let bc = bodyCondition else { return .gray }
        switch bc.category {
        case .severelyUnderweight, .obese:
            return .red
        case .underweight, .overweight:
            return .orange
        case .lean, .slightlyOverweight:
            return .yellow
        case .ideal:
            return .green
        }
    }
    
    private var bcsCategoryText: String {
        bodyCondition?.category.rawValue ?? "—"
    }
    
    // MARK: - Display strings
    
    private var petSubtitle: String {
        guard let pet = currentPet else { return "" }
        let years = pet.ageYears == 1 ? "1 year old" : "\(pet.ageYears) years old"
        return "\(pet.breedEnum.rawValue) • \(years)"
    }
    
    private var weightDisplay: String {
        guard let pet = currentPet else { return "--" }
        return String(format: "%.1f kg", pet.weightKg)
    }
    
    private var caloriesGoalText: String {
        guard let g = currentPet?.goals else { return "--" }
        return "\(g.targetCaloriesPerDay) kcal"
    }
    
    private var waterGoalText: String {
        guard let g = currentPet?.goals else { return "--" }
        return "\(g.targetWaterMlPerDay) ml"
    }
    
    private var caloriesProgress: Double {
        guard let goal = currentPet?.goals?.targetCaloriesPerDay, goal > 0 else { return 0 }
        return min(1.0, Double(caloriesToday) / Double(goal))
    }
    
    private var waterProgress: Double {
        guard let goal = currentPet?.goals?.targetWaterMlPerDay, goal > 0 else { return 0 }
        return min(1.0, Double(waterMlToday) / Double(goal))
    }
    
    // MARK: - Subviews
    
    private func statBadge(icon: String, label: String, value: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - BCS Detail Sheet

private struct BCSDetailSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let bodyCondition: BodyCondition
    let petName: String
    let breedName: String
    
    @State private var isDisclaimerExpanded: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(scoreTint.opacity(0.18))
                                .frame(width: 64, height: 64)
                            Text("\(bodyCondition.score)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(scoreTint)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Score: \(bodyCondition.score)/9")
                                .font(.headline)
                            Text(bodyCondition.category.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(scoreTint)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    detailRow(
                        icon: "arrow.left.and.right.circle.fill",
                        tint: .blue,
                        label: "Ideal range for \(breedName)",
                        value: rangeText
                    )
                    
                    detailRow(
                        icon: "target",
                        tint: .green,
                        label: "Target weight for BCS 5",
                        value: "\(petName) would need to be around \(formattedTarget) kg"
                    )
                    
                    DisclosureGroup(isExpanded: $isDisclaimerExpanded) {
                        Text(disclaimerText)
                            .font(.footnote)
                            .foregroundStyle(Color.secondary)
                            .padding(.top, 8)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.gray)
                            Text("About this score")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.top, 4)
                    
                    Spacer(minLength: 16)
                }
                .padding()
            }
            .navigationTitle("Body Condition Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private var scoreTint: Color {
        switch bodyCondition.category {
        case .severelyUnderweight, .obese:
            return .red
        case .underweight, .overweight:
            return .orange
        case .lean, .slightlyOverweight:
            return .yellow
        case .ideal:
            return .green
        }
    }
    
    private var rangeText: String {
        let lo = String(format: "%.1f", bodyCondition.idealRangeKg.lowerBound)
        let hi = String(format: "%.1f", bodyCondition.idealRangeKg.upperBound)
        return "\(lo) – \(hi) kg"
    }
    
    private var formattedTarget: String {
        String(format: "%.1f", bodyCondition.targetWeightKg)
    }
    
    private var disclaimerText: String {
        """
        BCS is a 1–9 screening scale recommended by the AAFP. \
        5 out of 9 is recommended as the clinical ideal. This estimate \
        uses your cat's weight relative to their breed's healthy range; \
        consult a veterinarian for a definitive assessment.
        """
    }
    
    private func detailRow(icon: String,
                           tint: Color,
                           label: String,
                           value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 24)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            Spacer()
        }
    }
}

// MARK: - ProgressGoalCard (calories, water)

private struct ProgressGoalCard: View {
    let icon: String
    let title: String
    let currentText: String
    let goalText: String
    let progress: Double
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundStyle(color)
                .padding(10)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(currentText) / \(goalText)")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 44, height: 44)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - CountGoalCard (restroom)

private struct CountGoalCard: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundStyle(color)
                .padding(10)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(visitsLabel)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            
            Spacer()
            
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.15))
                .clipShape(Circle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var visitsLabel: String {
        count == 1 ? "1 visit" : "\(count) visits"
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthService.previewMock)
        .modelContainer(for: [User.self, Pet.self, PetGoals.self, LogEntry.self, Item.self],
                        inMemory: true)
}
