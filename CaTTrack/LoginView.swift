//
//  LoginView.swift
//  CaTTrack
//
//  Sign-in form for existing users.
//
//  Same view-identity pattern as RegisterView: fields are inlined and
//  each is tagged with .id(...) so SwiftUI keeps their @State distinct.
//

import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject private var auth: AuthService
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isSubmitting: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .foregroundStyle(.blue)
                    
                    Text("Welcome Back")
                        .font(.title2)
                        .bold()
                    
                    Text("Sign in to continue tracking.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)
                
                // ------------------------------
                // Form — inlined for stable identity
                // ------------------------------
                VStack(spacing: 16) {
                    
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
                    .id("login_field_email")
                    
                    // Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 24)
                            SecureField("Your password", text: $password)
                                .textContentType(.password)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    .id("login_field_password")
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
                
                Button(action: submit) {
                    HStack {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Sign In")
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
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var isFormFilled: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    private func submit() {
        errorMessage = nil
        isSubmitting = true
        
        do {
            try auth.login(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSubmitting = false
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AuthService.previewMock)
    }
}
