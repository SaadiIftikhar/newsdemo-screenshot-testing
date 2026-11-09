import NewsCore
import SwiftUI

/// Shown when a reader without a PLUS subscription taps a PLUS article (decided by `ArticleAccess`).
/// The two entitlement variants are snapshot-tested on both platforms: this screen is where subscription
/// revenue comes from, so it is protected like the PLUS badge itself.
public struct PaywallView: View {
    let entitlement: Entitlement
    var onSubscribe: () -> Void
    var onSignIn: () -> Void
    var onClose: () -> Void

    public init(entitlement: Entitlement, onSubscribe: @escaping () -> Void = {},
                onSignIn: @escaping () -> Void = {}, onClose: @escaping () -> Void = {}) {
        self.entitlement = entitlement
        self.onSubscribe = onSubscribe
        self.onSignIn = onSignIn
        self.onClose = onClose
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    PremiumBadge()
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark").font(.headline).frame(width: 44, height: 44)
                    }
                    .foregroundStyle(NewsTheme.textSecondary)
                    .accessibilityLabel("Schließen")
                }
                Text("Weiterlesen mit PLUS")
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(NewsTheme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(entitlement == .registered
                     ? "Du bist angemeldet, hast aber noch kein PLUS-Abo."
                     : "Dieser Artikel gehört zu PLUS.")
                    .font(.body)
                    .foregroundStyle(NewsTheme.textSecondary)
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(["Alle PLUS-Artikel und Hintergründe", "Weniger Werbung", "Monatlich kündbar"], id: \.self) { benefit in
                        Label(benefit, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(NewsTheme.textPrimary)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Demo-Angebot").font(.caption.weight(.bold)).foregroundStyle(NewsTheme.kicker)
                    Text("1 Monat gratis, danach 9,99 € / Monat").font(.headline).foregroundStyle(NewsTheme.textPrimary)
                }
                .padding(NewsTheme.spacing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(NewsTheme.card, in: RoundedRectangle(cornerRadius: NewsTheme.cornerRadius))
                Button(action: onSubscribe) {
                    Text("PLUS testen").bold().frame(maxWidth: .infinity).padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(NewsTheme.breakingRed)
                if entitlement == .anonymous {
                    Button("Bereits Abonnent? Anmelden", action: onSignIn)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(NewsTheme.accentText)
                }
            }
            .padding(NewsTheme.spacing)
        }
        .background(NewsTheme.background)
    }
}
