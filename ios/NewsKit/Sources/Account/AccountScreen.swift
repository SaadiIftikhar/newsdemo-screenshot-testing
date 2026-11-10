import NewsCore
import NewsUI
import Observation
import SwiftUI

@MainActor
@Observable
public final class AccountViewModel {
    public enum State: Equatable {
        case signedOut
        case submitting
        case failed(String)
        case signedIn(UserProfile)
    }

    public var email: String
    public var password: String
    public private(set) var fieldErrors = LoginValidator.Errors()
    public private(set) var state: State
    private let client: AuthClient

    public init(client: AuthClient = .demo, email: String = "", password: String = "", state: State = .signedOut) {
        self.client = client
        self.email = email
        self.password = password
        self.state = state
    }

    /// Paywall decisions are based on this (see `ArticleAccess`).
    public var entitlement: Entitlement {
        if case .signedIn(let profile) = state { return profile.isPremium ? .subscriber : .registered }
        return .anonymous
    }

    public func signIn() async {
        fieldErrors = LoginValidator.validate(email: email, password: password)
        guard fieldErrors.isEmpty else {
            announce(fieldErrors.email ?? fieldErrors.password ?? "")
            return
        }
        state = .submitting
        do {
            state = .signedIn(try await client.signIn(email, password))
            password = ""
        } catch AuthError.invalidCredentials {
            state = .failed(Self.wrongCredentials)
        } catch AuthError.offline {
            state = .failed(Self.offline)
        } catch {
            state = .failed(Self.generic) // one of three fixed messages: wrong credentials, offline, generic
        }
        if case .failed(let message) = state { announce(message) }
    }

    static let wrongCredentials = "E-Mail-Adresse oder Passwort ist falsch."
    static let offline = "Keine Internetverbindung. Bitte später erneut versuchen."
    static let generic = "Anmeldung fehlgeschlagen. Bitte später erneut versuchen."

    /// VoiceOver users hear errors immediately instead of having to find them.
    private func announce(_ message: String) {
        guard !message.isEmpty else { return }
        AccessibilityNotification.Announcement(message).post()
    }

    public func signOut() {
        state = .signedOut
        email = ""
        password = ""
        fieldErrors = .init()
    }
}

/// The Account tab.
public struct AccountScreen: View {
    private let model: AccountViewModel // owned by the app shell (it also drives the paywall)

    public init(model: AccountViewModel) { self.model = model }

    public var body: some View {
        NavigationStack {
            Group {
                if case .signedIn(let profile) = model.state {
                    ProfileView(profile: profile, onSignOut: model.signOut)
                } else {
                    LoginForm(model: model)
                }
            }
            .navigationTitle("Konto")
        }
    }
}

struct LoginForm: View {
    @Bindable var model: AccountViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Melde dich an, um deine PLUS-Artikel auf allen Geräten zu lesen.")
                    .font(.subheadline)
                    .foregroundStyle(NewsTheme.textSecondary)

                if case .failed(let message) = model.state {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(NewsTheme.breakingRed, in: RoundedRectangle(cornerRadius: 8))
                }

                field(title: "E-Mail", error: model.fieldErrors.email) {
                    // `prompt: Text(verbatim:)`: a plain string literal is parsed as Markdown and the
                    // e-mail address became a blue link (caught in the login snapshot).
                    TextField("E-Mail", text: $model.email, prompt: Text(verbatim: "name@beispiel.de"))
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("email")
                }
                field(title: "Passwort", error: model.fieldErrors.password) {
                    SecureField("Passwort", text: $model.password, prompt: Text(verbatim: "Min. 8 Zeichen")) // the longer text clipped at the largest text size (a11y audit)
                        .textContentType(.password)
                        .accessibilityIdentifier("password")
                }

                Button {
                    Task { await model.signIn() }
                } label: {
                    // Static text instead of a spinner: deterministic in snapshots, clearer for VoiceOver.
                    Text(model.state == .submitting ? "Wird angemeldet …" : "Anmelden").bold()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(NewsTheme.breakingRed)
                .disabled(model.state == .submitting)
                .accessibilityIdentifier("sign-in")

                Text(verbatim: "Demo-Zugang: \(AuthClient.demoEmail) / \(AuthClient.demoPassword)")
                    .font(.footnote)
                    .foregroundStyle(NewsTheme.textSecondary)
            }
            .padding(NewsTheme.spacing)
        }
        .background(NewsTheme.background)
    }

    private func field<Input: View>(title: String, error: String?, @ViewBuilder input: () -> Input) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(NewsTheme.textPrimary)
            input()
                .padding(10)
                .background(NewsTheme.card, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(error == nil ? .clear : NewsTheme.breakingRed, lineWidth: 1.5))
            if let error {
                Text(error).font(.footnote).foregroundStyle(NewsTheme.accentText)
            }
        }
    }
}

struct ProfileView: View {
    let profile: UserProfile
    let onSignOut: () -> Void

    private var initials: String {
        profile.name.split(separator: " ").compactMap(\.first).prefix(2).map(String.init).joined()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(initials)
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(NewsTheme.breakingRed, in: Circle())
                    .accessibilityHidden(true) // initials avatar is decorative; the name follows
                VStack(spacing: 4) {
                    Text(profile.name).font(.title2.weight(.bold)).foregroundStyle(NewsTheme.textPrimary)
                    Text(profile.email).font(.subheadline).foregroundStyle(NewsTheme.textSecondary)
                        .accessibilityLabel("E-Mail-Adresse: \(profile.email)") // a bare address is not a readable label
                }
                if profile.isPremium {
                    Label("PLUS-Abo aktiv", systemImage: "star.fill")
                        .font(.subheadline.weight(.heavy))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(NewsTheme.premiumGold, in: Capsule())
                        .foregroundStyle(.black)
                }
                VStack(spacing: 0) {
                    ForEach(["Benachrichtigungen", "Newsletter", "Datenschutz"], id: \.self) { title in
                        // No chevron: these rows are not interactive in the demo, and a chevron promised a tap.
                        HStack {
                            Text(title).foregroundStyle(NewsTheme.textPrimary)
                            Spacer()
                        }
                        .padding(NewsTheme.spacing)
                        if title != "Datenschutz" { Divider().padding(.leading, NewsTheme.spacing) }
                    }
                }
                .background(NewsTheme.card, in: RoundedRectangle(cornerRadius: NewsTheme.cornerRadius))
                Button("Abmelden", role: .destructive, action: onSignOut)
                    .buttonStyle(.bordered)
                    // Neutral grey button + accentText label: the system red on its own red tint failed the
                    // accessibility audit's contrast check.
                    .tint(.gray)
                    .foregroundStyle(NewsTheme.accentText)
                    .accessibilityIdentifier("sign-out")
            }
            .padding(NewsTheme.spacing)
            .frame(maxWidth: .infinity)
        }
        .background(NewsTheme.background)
    }
}
