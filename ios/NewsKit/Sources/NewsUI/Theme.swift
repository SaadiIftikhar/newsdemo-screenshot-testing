import SwiftUI
import UIKit

/// Minimal design-system tokens. Colours adapt to light/dark through dynamic UIColors.
public enum NewsTheme {
    public static let breakingRed = Color(red: 0.82, green: 0.0, blue: 0.11)
    public static let liveRed = Color(red: 0.90, green: 0.10, blue: 0.15)
    public static let premiumGold = Color(red: 0.80, green: 0.62, blue: 0.16)

    public static let background = Color(uiColor: .systemBackground)
    public static let card = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(white: 0.13, alpha: 1) : UIColor(white: 0.97, alpha: 1) })
    public static let textPrimary = Color(uiColor: .label)
    public static let textSecondary = Color(uiColor: .secondaryLabel)
    public static let kicker = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 1.0, green: 0.45, blue: 0.45, alpha: 1) : UIColor(red: 0.75, green: 0.0, blue: 0.1, alpha: 1) })
    public static let adBackground = Color(uiColor: .tertiarySystemFill)

    public static let spacing: CGFloat = 12
    public static let cornerRadius: CGFloat = 10
}

/// Relative German timestamps, driven by injected `now`, locale and time zone.
public enum NewsDateFormatter {
    public static func relative(_ date: Date, now: Date, locale: Locale, timeZone: TimeZone) -> String {
        let minutes = Int(now.timeIntervalSince(date) / 60)
        switch minutes {
        case ..<1: return "gerade eben"
        case ..<60: return "vor \(minutes) Min."
        case ..<(24 * 60): return "vor \(minutes / 60) Std."
        default:
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.timeZone = timeZone
            formatter.dateFormat = "dd.MM.yyyy, HH:mm 'Uhr'"
            return formatter.string(from: date)
        }
    }

    public static func duration(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
