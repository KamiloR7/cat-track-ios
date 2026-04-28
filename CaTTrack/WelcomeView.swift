//
//  WelcomeView.swift
//  CaTTrack
//
//  Entry screen for unauthenticated users.
//  Offers two paths: Sign In (existing user) or Create Account (new user).
//
//  Pattern: NavigationStack drill-down (9 iOS Screen Navigation.pdf)
//  with SwiftUI DSL declarative views (11 Swift DSL.pdf, 12 SwiftUI.pdf).
//

import SwiftUI

struct WelcomeView: View {
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                
                Spacer()
                
                // Brand header
                VStack(spacing: 16) {
                    Image(systemName: "cat.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundStyle(.orange)
                    
                    Text("CaTTrack")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("Daily health insights for your cat.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Action buttons — drill down via NavigationLink
                // (NavigationLink is SwiftUI's wrapper of UISegue, per 12 SwiftUI.pdf)
                VStack(spacing: 12) {
                    
                    NavigationLink {
                        RegisterView()
                    } label: {
                        Text("Create Account")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(16)
                    }
                    
                    NavigationLink {
                        LoginView()
                    } label: {
                        Text("Sign In")
                            .font(.headline)
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 40)
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthService.previewMock)
}
