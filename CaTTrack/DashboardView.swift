//
//  DashboardView.swift
//  CaTTrack
//
//  Home tab. Shows the active cat profile and a minimizable
//  Daily Goals & Stats panel. Quick Actions has been removed in
//  favor of the bottom tab bar (see MainTabView).
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    
    @EnvironmentObject private var auth: AuthService
    
    @State private var isGoalsExpanded: Bool = true
    
    /// First registered pet for the current user. The project doc
    /// allows multiple pets in the future via a drop-down; for now
    /// we display the first one.
    private var currentPet: Pet? {
        auth.currentUser?.pets.first
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Cat Profile Card
                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            Image(systemName: "cat.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundStyle(.orange)
                                .padding(12)
                                .background(Color.orange.opacity(0.15))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(currentPet?.name ?? "—")
                                    .font(.title2)
                                    .bold()
                                Text(petSubtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        Divider()
                        
                        HStack(spacing: 24) {
                            statBadge(icon: "scalemass.fill",
                                      label: "Weight",
                                      value: weightDisplay)
                            statBadge(icon: "chart.bar.fill",
                                      label: "BMI",
                                      value: "--")
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
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                        }
                        .buttonStyle(.plain)
                        
                        if isGoalsExpanded {
                            VStack(spacing: 16) {
                                goalCard(icon: "flame.fill",
                                         title: "Calories",
                                         current: "0",
                                         goal: caloriesGoal,
                                         color: .red)
                                goalCard(icon: "drop.fill",
                                         title: "Water",
                                         current: "0",
                                         goal: waterGoal,
                                         color: .cyan)
                                goalCard(icon: "toilet.fill",
                                         title: "Restroom",
                                         current: "0",
                                         goal: "3 visits",
                                         color: .green)
                            }
                            .padding()
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                    
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
        }
    }
    
    // MARK: - Computed display strings
    
    private var petSubtitle: String {
        guard let pet = currentPet else { return "" }
        let years = pet.ageYears == 1 ? "1 year old" : "\(pet.ageYears) years old"
        return "\(pet.breedEnum.rawValue) • \(years)"
    }
    
    private var weightDisplay: String {
        guard let pet = currentPet else { return "--" }
        return String(format: "%.1f kg", pet.weightKg)
    }
    
    private var caloriesGoal: String {
        guard let g = currentPet?.goals else { return "--" }
        return "\(g.targetCaloriesPerDay) kcal"
    }
    
    private var waterGoal: String {
        guard let g = currentPet?.goals else { return "--" }
        return "\(g.targetWaterMlPerDay) ml"
    }
    
    // MARK: - Subviews
    
    private func statBadge(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func goalCard(icon: String,
                          title: String,
                          current: String,
                          goal: String,
                          color: Color) -> some View {
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
                Text("\(current) / \(goal)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 40, height: 40)
                Circle()
                    .trim(from: 0, to: 0.0)
                    .stroke(color,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                Text("0%")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthService.previewMock)
        .modelContainer(for: [User.self, Pet.self, PetGoals.self, LogEntry.self, Item.self],
                        inMemory: true)
}
