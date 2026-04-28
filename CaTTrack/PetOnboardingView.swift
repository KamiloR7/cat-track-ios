//
//  PetOnboardingView.swift
//  CaTTrack
//
//  Step 1 of 2 — basic pet info (name, breed, age, weight).
//
//  Breed selection is constrained to CatBreed.allCases so users
//  cannot type free-form breeds the Health AI Engine would not
//  recognize.
//
//  Persistence happens in Step 2 (PetGoalsView). That keeps the
//  state machine simple: if the user backs out of Step 2 nothing
//  is committed to the SwiftData store.
//

import SwiftUI
import SwiftData

struct PetOnboardingView: View {
    
    @EnvironmentObject private var auth: AuthService
    
    // @State backs each form field (12 SwiftUI.pdf — TextField requires
    // a binding variable).
    @State private var catName: String = ""
    @State private var selectedBreed: CatBreed = .domesticShorthair
    @State private var age: String = ""
    @State private var weight: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "cat.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundStyle(.orange)
                        
                        if let user = auth.currentUser {
                            Text("Welcome, \(user.name)!")
                                .font(.largeTitle)
                                .bold()
                        } else {
                            Text("Welcome to CaTTrack")
                                .font(.largeTitle)
                                .bold()
                        }
                        
                        Text("Step 1 of 2 — Tell us about your cat.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)
                    
                    // Form
                    VStack(spacing: 20) {
                        
                        // Cat Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cat Name")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            HStack(spacing: 12) {
                                Image(systemName: "pawprint.fill")
                                    .foregroundStyle(.orange)
                                    .frame(width: 24)
                                TextField("e.g. Whiskers", text: $catName)
                                    .textInputAutocapitalization(.words)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        .id("pet_name")
                        
                        // Breed — Picker bound to CatBreed enum
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Breed")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            HStack(spacing: 12) {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(.orange)
                                    .frame(width: 24)
                                
                                // ForEach over CaseIterable.allCases
                                // (per 11 - Enum.swift). The .menu style
                                // gives a native dropdown look.
                                Picker("Breed", selection: $selectedBreed) {
                                    ForEach(CatBreed.allCases) { breed in
                                        Text(breed.rawValue).tag(breed)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        .id("pet_breed")
                        
                        // Age
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Age (years)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .foregroundStyle(.orange)
                                    .frame(width: 24)
                                TextField("e.g. 3", text: $age)
                                    .keyboardType(.numberPad)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        .id("pet_age")
                        
                        // Current Weight
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Weight (kg)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            HStack(spacing: 12) {
                                Image(systemName: "scalemass.fill")
                                    .foregroundStyle(.orange)
                                    .frame(width: 24)
                                TextField("e.g. 4.5", text: $weight)
                                    .keyboardType(.decimalPad)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        .id("pet_weight")
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
                    
                    // "Step 2" button — NavigationLink pushes PetGoalsView.
                    // We validate first and then enable the link via the
                    // disabled() modifier.
                    NavigationLink {
                        if let draft = makeDraft() {
                            PetGoalsView(draft: draft)
                        } else {
                            // Should not happen given the validation guard,
                            // but the API requires a destination view.
                            EmptyView()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Step 2")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .cornerRadius(16)
                    }
                    .disabled(!isFormValid)
                    .simultaneousGesture(TapGesture().onEnded {
                        // Surface validation errors if user taps anyway.
                        _ = makeDraft()
                    })
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out") { auth.logout() }
                        .foregroundStyle(.red)
                }
            }
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        guard !catName.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        guard let ageInt = Int(age), ageInt >= 0 else { return false }
        guard let weightDouble = Double(weight), weightDouble > 0 else { return false }
        _ = ageInt; _ = weightDouble
        return true
    }
    
    /// Builds the in-memory draft to pass to Step 2. Returns nil and
    /// sets errorMessage if any field fails to parse.
    private func makeDraft() -> PetDraft? {
        errorMessage = nil
        
        let trimmed = catName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter your cat's name."
            return nil
        }
        guard let ageInt = Int(age), ageInt >= 0 else {
            errorMessage = "Age must be a non-negative whole number."
            return nil
        }
        guard let weightDouble = Double(weight), weightDouble > 0 else {
            errorMessage = "Weight must be a positive number (e.g. 4.5)."
            return nil
        }
        
        return PetDraft(name: trimmed,
                        breed: selectedBreed,
                        ageYears: ageInt,
                        weightKg: weightDouble)
    }
}

// MARK: - PetDraft (value type, passed between onboarding steps)
//
// Pattern reference: 10 - Struct.swift — struct with copy-by-value
// semantics is the right shape for a transient form payload.

struct PetDraft: Hashable {
    let name: String
    let breed: CatBreed
    let ageYears: Int
    let weightKg: Double
}

#Preview {
    PetOnboardingView()
        .environmentObject(AuthService.previewMock)
        .modelContainer(for: [User.self, Pet.self, PetGoals.self, LogEntry.self, Item.self],
                        inMemory: true)
}
