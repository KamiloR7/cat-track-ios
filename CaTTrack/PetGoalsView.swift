//
//  PetGoalsView.swift
//  CaTTrack
//
//  Step 2 of 2 — target ceilings used by the future graph view as
//  dotted reference lines. Persistence (Pet + PetGoals) happens
//  here, on the "Finish" tap, so a back-out from this screen leaves
//  no orphan rows in the database.
//

import SwiftUI
import SwiftData

struct PetGoalsView: View {
    
    @EnvironmentObject private var auth: AuthService
    @Environment(\.modelContext) private var modelContext
    
    let draft: PetDraft
    
    @State private var targetWeight: String = ""
    @State private var targetFood: String = ""
    @State private var targetWater: String = ""
    @State private var errorMessage: String?
    @State private var isSaving: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.blue)
                    
                    Text("Set Daily Targets")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("Step 2 of 2 — These targets become the ceiling lines on \(draft.name)'s health graphs.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.top, 24)
                
                // Form
                VStack(spacing: 20) {
                    
                    // Target Weight
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Weight (kg)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        HStack(spacing: 12) {
                            Image(systemName: "scalemass")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            TextField("e.g. 4.5", text: $targetWeight)
                                .keyboardType(.decimalPad)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    .id("goal_weight")
                    
                    // Target Food (kcal/day)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Food Limit (kcal/day)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        HStack(spacing: 12) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.red)
                                .frame(width: 24)
                            TextField("e.g. 250", text: $targetFood)
                                .keyboardType(.numberPad)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    .id("goal_food")
                    
                    // Target Water (ml/day)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Target Water Limit (ml/day)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        HStack(spacing: 12) {
                            Image(systemName: "drop.fill")
                                .foregroundStyle(.cyan)
                                .frame(width: 24)
                            TextField("e.g. 200", text: $targetWater)
                                .keyboardType(.numberPad)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    .id("goal_water")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(20)
                
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
                
                Button(action: finish) {
                    HStack {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Finish")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormFilled ? Color.green : Color.gray)
                    .cornerRadius(16)
                }
                .disabled(!isFormFilled || isSaving)
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Daily Targets")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var isFormFilled: Bool {
        !targetWeight.isEmpty && !targetFood.isEmpty && !targetWater.isEmpty
    }
    
    // MARK: - Persistence (do/try/catch — 2 Overview of Swift Features.pdf)
    
    private func finish() {
        errorMessage = nil
        
        // Optional binding (3 - ControlFlow.swift)
        guard let weight = Double(targetWeight), weight > 0 else {
            errorMessage = "Target weight must be a positive number."
            return
        }
        guard let kcal = Int(targetFood), kcal > 0 else {
            errorMessage = "Target food limit must be a positive whole number."
            return
        }
        guard let ml = Int(targetWater), ml > 0 else {
            errorMessage = "Target water limit must be a positive whole number."
            return
        }
        guard let owner = auth.currentUser else {
            errorMessage = "No active user session."
            return
        }
        
        isSaving = true
        
        // 1. Build the Pet using the draft from Step 1.
        let pet = Pet(name: draft.name,
                      breed: draft.breed,
                      ageYears: draft.ageYears,
                      weightKg: draft.weightKg,
                      owner: owner)
        
        // 2. Build the PetGoals and link.
        let goals = PetGoals(targetWeightKg: weight,
                             targetCaloriesPerDay: kcal,
                             targetWaterMlPerDay: ml,
                             pet: pet)
        pet.goals = goals
        
        // 3. Insert + persist atomically.
        modelContext.insert(pet)
        modelContext.insert(goals)
        owner.pets.append(pet)
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Could not save: \(error.localizedDescription)"
            isSaving = false
            return
        }
        
        isSaving = false
        // ContentView observes auth.currentUser.pets.count and will
        // swap the root over to MainTabView automatically.
    }
}

#Preview {
    NavigationStack {
        PetGoalsView(draft: PetDraft(name: "Whiskers",
                                     breed: .siamese,
                                     ageYears: 3,
                                     weightKg: 4.5))
            .environmentObject(AuthService.previewMock)
            .modelContainer(for: [User.self, Pet.self, PetGoals.self, LogEntry.self, Item.self],
                            inMemory: true)
    }
}
