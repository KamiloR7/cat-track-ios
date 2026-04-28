//
//  AuthService.swift
//  CaTTrack
//
//  Local authentication service.
//  Pattern reference:
//   - 12 SwiftUI.pdf — ObservableObject protocol, @Published annotation
//   - 6 - OOP Encapsulation.swift — class with stored properties + methods
//   - SQLite.swift — Prof. Shen's UserStore lookup-by-email pattern
//
//  All credentials are stored locally via SwiftData. The password is
//  never stored in plaintext — we keep a SHA-256 hash. This is a
//  showcase app with no backend, so there is no network transmission.
//

import Foundation
import SwiftData
import CryptoKit
import Combine

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case emptyField
    case invalidEmail
    case passwordTooShort
    case passwordsDoNotMatch
    case emailAlreadyRegistered
    case invalidCredentials
    case storageFailure
    
    var errorDescription: String? {
        switch self {
        case .emptyField:              return "Please fill in every field."
        case .invalidEmail:            return "That email address is not valid."
        case .passwordTooShort:        return "Password must be at least 6 characters."
        case .passwordsDoNotMatch:     return "Passwords do not match."
        case .emailAlreadyRegistered:  return "An account with that email already exists."
        case .invalidCredentials:      return "Email or password is incorrect."
        case .storageFailure:          return "Could not save to local storage."
        }
    }
}

// MARK: - AuthService

final class AuthService: ObservableObject {
    
    // The currently-signed-in user. Nil means the auth flow should be shown.
    // @Published broadcasts changes to any SwiftUI view observing this object.
    @Published private(set) var currentUser: User?
    
    private let context: ModelContext
    
    // MARK: Initializer (designated, per 6 - OOP Encapsulation.swift)
    init(context: ModelContext) {
        self.context = context
    }
    
    // MARK: - Public API
    
    /// Creates a new local account and signs the user in.
    func register(name: String,
                  email: String,
                  password: String,
                  confirmPassword: String) throws {
        
        // 1. Field validation
        let trimmedName  = name.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        
        guard !trimmedName.isEmpty,
              !trimmedEmail.isEmpty,
              !password.isEmpty else {
            throw AuthError.emptyField
        }
        
        guard Self.isValidEmail(trimmedEmail) else {
            throw AuthError.invalidEmail
        }
        
        guard password.count >= 6 else {
            throw AuthError.passwordTooShort
        }
        
        guard password == confirmPassword else {
            throw AuthError.passwordsDoNotMatch
        }
        
        // 2. Uniqueness check (mirrors UserStore.allUsers() lookup)
        if try fetchUser(byEmail: trimmedEmail) != nil {
            throw AuthError.emailAlreadyRegistered
        }
        
        // 3. Persist
        let newUser = User(
            name: trimmedName,
            email: trimmedEmail,
            passwordHash: Self.hash(password)
        )
        context.insert(newUser)
        
        do {
            try context.save()
        } catch {
            throw AuthError.storageFailure
        }
        
        // 4. Sign in
        currentUser = newUser
    }
    
    /// Looks up an existing user and verifies the password.
    func login(email: String, password: String) throws {
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces).lowercased()
        
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            throw AuthError.emptyField
        }
        
        guard let user = try fetchUser(byEmail: trimmedEmail) else {
            throw AuthError.invalidCredentials
        }
        
        guard user.passwordHash == Self.hash(password) else {
            throw AuthError.invalidCredentials
        }
        
        currentUser = user
    }
    
    /// Clears the active session.
    func logout() {
        currentUser = nil
    }
    
    // MARK: - Private Helpers
    
    /// Fetches a user by email. Equivalent to a SELECT ... WHERE email = ?
    /// — see Prof. Shen's UserStore.allUsers() in SQLite.swift, narrowed
    /// here with a #Predicate (SwiftData's typed predicate API).
    private func fetchUser(byEmail email: String) throws -> User? {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.email == email }
        )
        return try context.fetch(descriptor).first
    }
    
    /// SHA-256 hash. CryptoKit is an Apple framework — no third-party.
    private static func hash(_ password: String) -> String {
        let data = Data(password.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Minimal RFC-style email check. Good enough for a showcase.
    private static func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^\S+@\S+\.\S+$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
}
