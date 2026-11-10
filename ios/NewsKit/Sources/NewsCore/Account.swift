import Foundation

public struct UserProfile: Equatable, Sendable {
    public var name: String
    public var email: String
    public var isPremium: Bool

    public init(name: String, email: String, isPremium: Bool) {
        self.name = name
        self.email = email
        self.isPremium = isPremium
    }
}

public enum AuthError: Error, Equatable, Sendable {
    case invalidCredentials
    case offline
}

/// Login seam, same pattern as `FeedClient`: screens depend on this value, tests swap it.
public struct AuthClient: Sendable {
    public var signIn: @Sendable (_ email: String, _ password: String) async throws -> UserProfile

    public init(signIn: @escaping @Sendable (String, String) async throws -> UserProfile) {
        self.signIn = signIn
    }
}

extension AuthClient {
    /// PLUS subscriber.
    public static let demoEmail = "demo@newsdemo.app"
    /// Registered reader without a subscription (sees the paywall on PLUS articles).
    public static let basicEmail = "basis@newsdemo.app"
    public static let demoPassword = "demo1234"

    /// Offline demo backend: two known accounts. No network, no secrets.
    public static let demo = AuthClient { email, password in
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard password == demoPassword else { throw AuthError.invalidCredentials }
        switch normalized {
        case demoEmail: return UserProfile(name: "Demo Leser", email: demoEmail, isPremium: true)
        case basicEmail: return UserProfile(name: "Basis Leser", email: basicEmail, isPremium: false)
        default: throw AuthError.invalidCredentials
        }
    }

    public static func failing(_ error: AuthError) -> AuthClient {
        AuthClient { _, _ in throw error }
    }
}

/// Client-side validation, run before calling the backend.
public enum LoginValidator {
    public struct Errors: Equatable, Sendable {
        public var email: String?
        public var password: String?
        public var isEmpty: Bool { email == nil && password == nil }

        public init(email: String? = nil, password: String? = nil) {
            self.email = email
            self.password = password
        }
    }

    public static func validate(email: String, password: String) -> Errors {
        var errors = Errors()
        // Trim whitespace AND newlines; length counted in Unicode code points (portable across platforms).
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            errors.email = "Bitte E-Mail-Adresse eingeben."
        } else if trimmed.range(of: #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#, options: .regularExpression) == nil {
            errors.email = "Bitte eine gültige E-Mail-Adresse eingeben."
        }
        if password.isEmpty {
            errors.password = "Bitte Passwort eingeben."
        } else if password.unicodeScalars.count < 8 {
            errors.password = "Das Passwort hat mindestens 8 Zeichen."
        }
        return errors
    }
}
