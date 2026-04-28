//
//  OnboardingView.swift
//  CaTTrack
//

import SwiftUI

struct OnboardingView: View {
    @State private var catName: String = ""
    @State private var breed: String = ""
    @State private var age: String = ""
    @State private var weight: String = ""
    @State private var isCalculating: Bool = false

    var onComplete: () -> Void

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

                        Text("Welcome to CaTTrack")
                            .font(.largeTitle)
                            .bold()

                        Text("Let’s set up your cat’s profile to get started.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    // Form
                    VStack(spacing: 20) {
                        inputField(icon: "pawprint.fill", label: "Cat Name", placeholder: "e.g. Whiskers", text: $catName)
                        inputField(icon: "tag.fill", label: "Breed", placeholder: "e.g. Siamese", text: $breed)
                        inputField(icon: "calendar", label: "Age (years)", placeholder: "e.g. 3", text: $age, keyboard: .numberPad)
                        inputField(icon: "scalemass.fill", label: "Current Weight (kg)", placeholder: "e.g. 4.5", text: $weight, keyboard: .decimalPad)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(20)

                    // Calculate Button
                    Button(action: {
                        isCalculating = true
                        // Placeholder: logic will go here later
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isCalculating = false
                            onComplete()
                        }
                    }) {
                        HStack {
                            if isCalculating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "chart.bar.fill")
                                Text("Calculate BMI & Baseline")
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(16)
                    }
                    .disabled(catName.isEmpty || breed.isEmpty || age.isEmpty || weight.isEmpty || isCalculating)
                    .opacity(catName.isEmpty || breed.isEmpty || age.isEmpty || weight.isEmpty ? 0.6 : 1.0)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private func inputField(icon: String, label: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(.orange)
                    .frame(width: 24)

                TextField(placeholder, text: text)
                    .keyboardType(keyboard)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}

