import UIKit

/// The styling contract for `SavedPayPalPaymentMethodView`.
///
/// Mirrors the platform-neutral three-group model defined in the styling doc
/// (`EditFiComponent(SavedPayPalPaymentMethodViewStyle) - Styling`): `root` (global type &
/// color), `component` (outer container box), and `layout` (per-zone visibility,
/// spacing & sizing), plus a `creditMessaging` group for the Pay Later line.
///
/// Field set, defaults, and guards match Android; only the types differ (`dp`/`sp` →
/// `CGFloat` points, with text sizes rendered through Dynamic Type; `@ColorInt` →
/// `UIColor`; `@FontRes` → `fontName` PostScript string). Merchant-supplied values are
/// clamped by `EditFiStyleGuard` at render time.
public struct SavedPayPalPaymentMethodViewStyle {

    public var root: RootStyle = RootStyle()
    public var component: ComponentStyle = ComponentStyle()
    public var layout: LayoutStyle = LayoutStyle()
    public var creditMessaging: CreditMessagingStyle = CreditMessagingStyle()

    public init() {}
}

/// Global type & color. Applies to the label, FI text, and credit messaging.
public struct RootStyle {

    /// Component background color. Default: white.
    public var backgroundColor: UIColor? = .white

    /// Base text color for label, FI text, and credit messaging. Default: ≈ `#222222`.
    public var textColorBase: UIColor? = UIColor(white: 0.133, alpha: 1)

    /// Accent color for the credit-messaging "Learn more" link. When `nil`, the link is
    /// distinguished by bold + underline in the base text color instead.
    public var primaryColor: UIColor?

    public init() {}
}

/// The outer container box.
public struct ComponentStyle {

    /// Fixed height. `nil` → intrinsic / wrap content (default).
    public var height: CGFloat?

    /// Leading/trailing padding. Default: 0.
    public var horizontalPadding: CGFloat = 0

    /// Top/bottom padding. Default: 10.
    public var verticalPadding: CGFloat = 10

    /// Container corner radius. Default: 0.
    public var cornerRadius: CGFloat = 0

    /// Container border color. Default: transparent (no visible border).
    public var borderColor: UIColor? = .clear

    /// Container border width. Default: 0.
    public var borderWidth: CGFloat = 0

    /// Optional background color behind the FI card icon. `nil` → none.
    public var cardIconBackgroundColor: UIColor?

    /// Corner radius for the FI card icon background. Default: 0.
    public var cardIconCornerRadius: CGFloat = 0

    /// Background color behind the FI cluster (card art + digits + pencil), forming the
    /// rounded pill. Defaults to a light gray to match the design; set `nil` for no pill.
    public var fiClusterBackgroundColor: UIColor? = .systemGray6

    public init() {}
}

/// Per-zone visibility, spacing & sizing.
public struct LayoutStyle {

    /// Show the PayPal brand logo. Default: `true`.
    public var showLogo: Bool = true

    /// Show the "PayPal" text label. Default: `true`.
    public var showLabel: Bool = true

    /// Gap between the logo and the label. Default: 6 (min 0, max 24 · pending design confirmation).
    public var logoLabelGap: CGFloat = 6

    /// Gap between the label cluster and the FI cluster. Default: 12 (min = default, max 32 · pending design confirmation).
    public var labelFiGap: CGFloat = 12

    /// "PayPal" label text size. Default: 20 pt · Dynamic Type (min = default, max 28 · pending design confirmation).
    public var labelFontSize: CGFloat = 20

    /// FI text size. Default: 14 pt · Dynamic Type (min = default, max 24 · pending design confirmation).
    public var fiTextFontSize: CGFloat = 14

    /// Edit (pencil) affordance size. Default: 16 pt (min = default, max 24 · pending design confirmation).
    public var iconSize: CGFloat = 16

    /// Registered custom-font PostScript name. `nil` → system font. Mirrors Android `@FontRes`.
    public var fontName: String?

    public init() {}
}

/// The inline credit (Pay Later) messaging line.
public struct CreditMessagingStyle {

    /// Whether the messaging line is enabled. Default: `true`.
    /// (Only rendered when the request also sets `showCreditMessage`.)
    public var enabled: Bool = true

    /// Placeholder message copy. Replaced by the fetched offer copy when the API is wired in.
    public var messageText: String = "Or 4 interest-free payments of $324.50."

    /// Placeholder "Learn more" copy.
    public var learnMoreText: String = "Learn more"

    /// Messaging text size. Default: 16 pt · Dynamic Type (min = default, max 24 · pending design confirmation).
    public var fontSize: CGFloat = 16

    public init() {}
}
