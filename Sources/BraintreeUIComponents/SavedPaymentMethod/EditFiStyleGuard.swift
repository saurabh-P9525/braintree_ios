import CoreGraphics

/// Platform-agnostic guardrails for `SavedPaymentMethodViewStyle` (styling doc §4).
///
/// Enforces the non-negotiable clamps regardless of merchant input. The "min = default,
/// may grow to a max" rows can be increased up to their max but never decreased below the
/// shipped default. Text-size fields are clamped at the base size only — Dynamic Type
/// scaling on top is intentionally left unbounded so accessibility is preserved.
///
/// Maxima marked `DTC` (Design Team to Confirm) are provisional pending design sign-off.
enum EditFiStyleGuard {

    // MARK: - Defaults (min bounds for the "min = default" fields)

    static let logoLabelGapDefault: CGFloat = 6
    static let labelFiGapDefault: CGFloat = 12
    static let labelFontSizeDefault: CGFloat = 20
    static let fiTextFontSizeDefault: CGFloat = 14
    static let iconSizeDefault: CGFloat = 16
    static let creditMessageFontSizeDefault: CGFloat = 16

    // MARK: - Maxima (DTC — pending design confirmation)

    static let logoLabelGapMax: CGFloat = 24
    static let labelFiGapMax: CGFloat = 32
    static let labelFontSizeMax: CGFloat = 28
    static let fiTextFontSizeMax: CGFloat = 24
    static let iconSizeMax: CGFloat = 24
    static let creditMessageFontSizeMax: CGFloat = 24

    // MARK: - Clamps

    /// Gap between the logo and the label: `[0, max]`.
    static func logoLabelGap(_ value: CGFloat) -> CGFloat {
        clamp(value, min: 0, max: logoLabelGapMax)
    }

    /// Gap between the label and FI clusters: `[default, max]`.
    static func labelFiGap(_ value: CGFloat) -> CGFloat {
        clamp(value, min: labelFiGapDefault, max: labelFiGapMax)
    }

    /// Label text size: `[default, max]`.
    static func labelFontSize(_ value: CGFloat) -> CGFloat {
        clamp(value, min: labelFontSizeDefault, max: labelFontSizeMax)
    }

    /// FI text size: `[default, max]`.
    static func fiTextFontSize(_ value: CGFloat) -> CGFloat {
        clamp(value, min: fiTextFontSizeDefault, max: fiTextFontSizeMax)
    }

    /// Edit-icon size: `[default, max]`.
    static func iconSize(_ value: CGFloat) -> CGFloat {
        clamp(value, min: iconSizeDefault, max: iconSizeMax)
    }

    /// Credit-messaging text size: `[default, max]`.
    static func creditMessageFontSize(_ value: CGFloat) -> CGFloat {
        clamp(value, min: creditMessageFontSizeDefault, max: creditMessageFontSizeMax)
    }

    // MARK: - Private Helpers

    private static func clamp(_ value: CGFloat, min lower: CGFloat, max upper: CGFloat) -> CGFloat {
        min(max(value, lower), upper)
    }
}
