//
//  RegisterView.swift
//  CaTTrack
//
//  Account creation form. On success, AuthService publishes the new
//  currentUser, which causes ContentView to advance to pet onboarding.
//
//  Note on view identity: SecureField and TextField are declared inline
//  (not through a generic `some View` helper) and each one is tagged
//  with .id(...). This guarantees SwiftUI treats each field as a
//  distinct view and does not collapse their state together.
//

import SwiftUI

struct RegisterView: View {
    
    @EnvironmentObject private var auth: AuthService
    
    // @State variables — each TextField/SecureField needs its own
    // binding (per 12 SwiftUI.pdf).
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String?
    @State private var isSubmitting: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .foregroundStyle(.blue)
                    
                    Text("Create Your Account")
                        .font(.title2)
                        .bold()
                    
                    Text("All data is stored locally.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)
                
                // ------------------------------
                // Form — inlined for stable identity
                // ------------------------------
                VStack(spacing: 16) {
                    
                    // Full Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Full Name")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            TextField("e.g. John Doe", text: $name)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    .id("field_name")
                    
                    // Email
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            TextField("you@example.com", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    .id("field_email")
                    
                    // Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            SecureField("At least 6 characters", text: $password)
                                .textContentType(.newPassword)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    .id("field_password")
                    
                    // Confirm Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Confirm Password")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        HStack(spacing: 12) {
                            Image(systemName: "lock.rotation")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            SecureField("Re-enter password", text: $confirmPassword)
                                .textContentType(.newPassword)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    .id("field_confirm_password")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(20)
                
                // Error banner — Optional unwrap (2 - OptionalType.swift)
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
                
                // Submit
                Button(action: submit) {
                    HStack {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Register")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormFilled ? Color.blue : Color.gray)
                    .cornerRadius(16)
                }
                .disabled(!isFormFilled || isSubmitting)
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Computed Property (per 6 - OOP Encapsulation.swift)
    private var isFormFilled: Bool {
        !name.isEmpty && !email.isEmpty &&
        !password.isEmpty && !confirmPassword.isEmpty
    }
    
    // MARK: - Action
    private func submit() {
        errorMessage = nil
        isSubmitting = true
        
        // do/try/catch — per 2 Overview of Swift Features.pdf
        do {
            try auth.register(name: name,
                              email: email,
                              password: password,
                              confirmPassword: confirmPassword)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSubmitting = false
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environmentObject(AuthService.previewMock)
    }
}
