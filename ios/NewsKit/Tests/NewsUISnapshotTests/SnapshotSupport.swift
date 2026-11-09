import NewsFixtures
import NewsUI
import SnapshotTesting
import SwiftUI
import UIKit
import XCTest

/// One rendering configuration in the state matrix. Names are shared with Android (see fixtures/README.md).
struct Variant: Sendable {
    let name: String
    let colorScheme: ColorScheme
    let dynamicType: DynamicTypeSize

    static let light = Variant(name: "light", colorScheme: .light, dynamicType: .large)
    static let dark = Variant(name: "dark", colorScheme: .dark, dynamicType: .large)
    /// Accessibility size AX3 (iOS goes up to AX5), where truncation/overlap bugs start to appear.
    static let largeText = Variant(name: "light_xxxl", colorScheme: .light, dynamicType: .accessibility3)

    /// Curated default matrix (not a full cartesian product — see STRATEGY.md "Scaling").
    static let standard: [Variant] = [.light, .dark, .largeText]

    var traits: UITraitCollection {
        UITraitCollection { traits in
            traits.userInterfaceStyle = colorScheme == .dark ? .dark : .light
            traits.preferredContentSizeCategory = UIContentSizeCategory(dynamicType) // exact mapping for any variant
            traits.layoutDirection = .leftToRight
        }
    }
}

extension ViewImageConfig {
    /// iPhone 13 width, tall enough to show a whole feed (screen goldens otherwise stop after the first screen).
    static let iPhone13FullHeight = ViewImageConfig(safeArea: .zero, size: CGSize(width: 390, height: 2700),
                                                    traits: ViewImageConfig.iPhone13.traits)
}

enum Snap {
    static let store = FixtureStore.repository()

    /// Visual tolerance, set once and explicitly:
    ///  - precision 1.0: every pixel is compared (no "ignore 2% of the image" loophole)
    ///  - perceptualPrecision 0.98: a pixel may differ by an imperceptible amount (ΔE ≈ 2), which absorbs
    ///    GPU anti-aliasing noise but still fails on a moved/recoloured element.
    static let precision: Float = 1.0
    static let perceptualPrecision: Float = 0.98

    static let componentWidth: CGFloat = 390
}

extension View {
    /// Pins every source of non-determinism the UI reads.
    @MainActor
    func deterministic(_ variant: Variant) -> some View {
        let store = Snap.store
        return self
            .environment(\.now, FixtureEnvironment.now)
            .environment(\.locale, FixtureEnvironment.locale)
            .environment(\.timeZone, FixtureEnvironment.timeZone)
            .environment(\.imageProvider, .local { store.image($0) })
            .environment(\.animationsEnabled, false)
            .environment(\.colorScheme, variant.colorScheme)
            .dynamicTypeSize(variant.dynamicType)
            .transaction { $0.disablesAnimations = true }
    }
}

/// Snapshot a component at a fixed width, letting height follow content, for each variant.
@MainActor
func assertComponent<V: View>(
    _ view: V,
    variants: [Variant] = Variant.standard,
    fileID: StaticString = #fileID, file: StaticString = #filePath,
    testName: String = #function, line: UInt = #line, column: UInt = #column
) {
    for variant in variants {
        let framed = view
            .padding(NewsTheme.spacing)
            .frame(width: Snap.componentWidth)
            // Ideal height in both the measuring and the rendering pass, so they agree.
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(NewsTheme.background)
            .deterministic(variant)
        // We host the view ourselves instead of using `.sizeThatFits`, which (a) renders inside a
        // device-sized window, so XXXL content taller than the screen was clipped, and (b) inherits the
        // window's safe-area insets, which squeezed tall content (summary cut to one line, white bands).
        // A snapshot that silently hides content is worse than no snapshot.
        let host = UIHostingController(rootView: framed)
        host.safeAreaRegions = []
        host.traitOverrides.userInterfaceStyle = variant.traits.userInterfaceStyle
        host.traitOverrides.preferredContentSizeCategory = variant.traits.preferredContentSizeCategory
        let size = host.sizeThatFits(in: CGSize(width: Snap.componentWidth, height: .greatestFiniteMagnitude))
        assertSnapshot(
            of: host as UIViewController,
            as: .image(on: ViewImageConfig(safeArea: .zero,
                                           size: CGSize(width: Snap.componentWidth, height: size.height.rounded(.up)),
                                           traits: variant.traits),
                       precision: Snap.precision, perceptualPrecision: Snap.perceptualPrecision),
            named: variant.name,
            fileID: fileID, file: file, testName: testName, line: line, column: column
        )
    }
}

/// Snapshot a full screen on a fixed device geometry, for each variant.
@MainActor
func assertScreen<V: View>(
    _ view: V,
    device: ViewImageConfig = .iPhone13,
    variants: [Variant] = Variant.standard,
    fileID: StaticString = #fileID, file: StaticString = #filePath,
    testName: String = #function, line: UInt = #line, column: UInt = #column
) {
    for variant in variants {
        assertSnapshot(
            of: view.deterministic(variant),
            as: .image(precision: Snap.precision, perceptualPrecision: Snap.perceptualPrecision,
                       layout: .device(config: device), traits: variant.traits),
            named: variant.name,
            fileID: fileID, file: file, testName: testName, line: line, column: column
        )
    }
}
