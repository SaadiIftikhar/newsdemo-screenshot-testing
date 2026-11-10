import SwiftUI
import UIKit

/// Raw colour tokens as UIColors (light/dark aware), so `ContrastTests` can resolve and measure them.
/// Every text/background pair is checked against WCAG AA (ContrastTests).
public enum NewsPalette {
    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? dark : light }
    }
    static func rgb(_ hex: UInt32, alpha: CGFloat = 1) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
    }

    public static let breakingRed = rgb(0xD1001C)
    /// Non-text only (the pulsing dot): 4.3:1 on the light card is too low for small text.
    public static let liveRed = rgb(0xE61A26)
    public static let premiumGold = rgb(0xCC9E29)

    public static let background = dynamic(light: .white, dark: .black)
    public static let card = dynamic(light: rgb(0xF7F7F7), dark: rgb(0x212121))
    public static let textPrimary = dynamic(light: .black, dark: .white)
    /// Light #6C6C70 (≈4.9:1 on the card). Apple's secondaryLabel was only ≈3.4:1 for 12pt text.
    public static let textSecondary = dynamic(light: rgb(0x6C6C70), dark: rgb(0xEBEBF5, alpha: 0.6))
    public static let kicker = dynamic(light: rgb(0xBF001A), dark: rgb(0xFF7373))
    /// Red used as TEXT (errors, conflicts, X, "LIVE"): brand red in light mode; on dark backgrounds the brand
    /// red is only ≈3.7:1, so a lighter red is used.
    public static let accentText = dynamic(light: rgb(0xD1001C), dark: rgb(0xFF7373))
    public static let adBackground = dynamic(light: rgb(0x767680, alpha: 0.12), dark: rgb(0x767680, alpha: 0.24))
    /// Solid (not blurred) so the floating tab bar renders identically in snapshots and on device.
    public static let tabBar = dynamic(light: UIColor(white: 1.0, alpha: 0.97), dark: UIColor(white: 0.16, alpha: 0.97))
    public static let tabBarBorder = dynamic(light: UIColor(white: 0, alpha: 0.08), dark: UIColor(white: 1, alpha: 0.12))
}

/// SwiftUI view of the tokens.
public enum NewsTheme {
    public static let breakingRed = Color(uiColor: NewsPalette.breakingRed)
    public static let liveRed = Color(uiColor: NewsPalette.liveRed)
    public static let premiumGold = Color(uiColor: NewsPalette.premiumGold)
    public static let background = Color(uiColor: NewsPalette.background)
    public static let card = Color(uiColor: NewsPalette.card)
    public static let textPrimary = Color(uiColor: NewsPalette.textPrimary)
    public static let textSecondary = Color(uiColor: NewsPalette.textSecondary)
    public static let kicker = Color(uiColor: NewsPalette.kicker)
    public static let accentText = Color(uiColor: NewsPalette.accentText)
    public static let adBackground = Color(uiColor: NewsPalette.adBackground)
    public static let tabBar = Color(uiColor: NewsPalette.tabBar)
    public static let tabBarBorder = Color(uiColor: NewsPalette.tabBarBorder)

    public static let spacing: CGFloat = 12
    public static let cornerRadius: CGFloat = 10
}

/// Relative German timestamps, driven by injected `now` and time zone.
public enum NewsDateFormatter {
    /// The product is German: absolute dates are ALWAYS formatted in de_DE, never with the device locale.
    /// (On an en_US device the 12-hour preference once leaked in as "11:05 PM Uhr".)
    public static func relative(_ date: Date, now: Date, locale: Locale = Locale(identifier: "de_DE"),
                                timeZone: TimeZone) -> String {
        let minutes = Int(now.timeIntervalSince(date) / 60)
        switch minutes {
        case ..<1: return "gerade eben"
        case ..<60: return "vor \(minutes) Min."
        case ..<(24 * 60): return "vor \(minutes / 60) Std."
        default:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "de_DE")
            formatter.timeZone = timeZone
            formatter.dateFormat = "dd.MM.yyyy, HH:mm 'Uhr'"
            return formatter.string(from: date)
        }
    }

    /// "4:05", and "1:02:03" from one hour on (it used to show "62:03").
    public static func duration(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return s >= 3600
            ? String(format: "%d:%02d:%02d", s / 3600, s / 60 % 60, s % 60)
            : String(format: "%d:%02d", s / 60, s % 60)
    }

    /// When cached content was loaded: "15:02 Uhr" today, "04.11.2026, 15:02 Uhr" on another day.
    public static func asOf(_ date: Date, now: Date, timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.timeZone = timeZone
        formatter.dateFormat = calendar.isDate(date, inSameDayAs: now) ? "HH:mm 'Uhr'" : "dd.MM.yyyy, HH:mm 'Uhr'"
        return formatter.string(from: date)
    }
}
