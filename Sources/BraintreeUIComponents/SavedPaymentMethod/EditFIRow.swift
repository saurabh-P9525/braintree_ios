import SwiftUI
import UIKit

/// The funding-instrument chip: `[badge] PayPal  [ card-art •• 1234  ✎ ]`.
///
/// The brand mark (badge + "PayPal") sits on the left; the FI (card art + last digits + edit
/// pencil) sits in a rounded pill to its right. Renders three variants:
/// - `.instrument` — card art (or generic fallback glyph) + last digits + edit pencil
/// - `.displayOnly` — buyer email + edit pencil (no-FI-but-email fallback)
/// - `.brandOnly` — PayPal brand mark only (no-network fallback)
struct EditFIRow: View {

    enum Content: Equatable {
        case instrument(FiSummary)
        case displayOnly(email: String)
        case brandOnly
    }

    let content: Content
    let style: SavedPaymentMethodViewStyle
    let onEdit: () -> Void

    // MARK: - Layout constants

    private let pillCornerRadius: CGFloat = 12
    private let pillHorizontalPadding: CGFloat = 10
    private let pillVerticalPadding: CGFloat = 6
    private let fiInnerSpacing: CGFloat = 8
    private let cardArtWidth: CGFloat = 30
    private let cardArtHeight: CGFloat = 20

    // MARK: - Derived style values (guarded)

    private var textColor: Color {
        Color(uiColor: style.root.textColorBase ?? UIColor(white: 0.133, alpha: 1))
    }

    private var fiFont: Font {
        SavedPaymentMethodFont.font(
            name: style.layout.fontName,
            size: EditFiStyleGuard.fiTextFontSize(style.layout.fiTextFontSize)
        )
    }

    private var editIconSide: CGFloat {
        EditFiStyleGuard.iconSize(style.layout.iconSize)
    }

    private var labelFiGap: CGFloat {
        EditFiStyleGuard.labelFiGap(style.layout.labelFiGap)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            brandCluster

            switch content {
            case .instrument(let summary):
                fiPill {
                    fiIcon(for: summary)
                    Text(fiText(for: summary))
                        .font(fiFont)
                        .foregroundColor(textColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    editButton
                }
                .padding(.leading, labelFiGap)
            case .displayOnly(let email):
                fiPill {
                    Text(email)
                        .font(fiFont)
                        .foregroundColor(textColor)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    editButton
                }
                .padding(.leading, labelFiGap)
            case .brandOnly:
                EmptyView()
            }

            // Keep the cluster left-aligned; the pill hugs the brand mark.
            Spacer(minLength: 0)
        }
    }

    // MARK: - Subviews

    private var brandCluster: some View {
        PayPalBrandCluster(style: style)
    }

    /// The rounded gray pill wrapping the FI content + edit pencil.
    private func fiPill<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack(spacing: fiInnerSpacing) {
            content()
        }
        .padding(.horizontal, pillHorizontalPadding)
        .padding(.vertical, pillVerticalPadding)
        .background(pillBackground)
    }

    @ViewBuilder private var pillBackground: some View {
        if let color = style.component.fiClusterBackgroundColor {
            RoundedRectangle(cornerRadius: pillCornerRadius).fill(Color(uiColor: color))
        }
    }

    @ViewBuilder private func fiIcon(for summary: FiSummary) -> some View {
        Group {
            if let url = summary.imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFit()
                    default:
                        // No-image-load fallback → generic glyph.
                        fallbackGlyph(for: summary)
                    }
                }
            } else {
                fallbackGlyph(for: summary)
            }
        }
        .frame(width: cardArtWidth, height: cardArtHeight)
        .background(cardIconBackground)
        .clipShape(RoundedRectangle(cornerRadius: style.component.cardIconCornerRadius > 0 ? style.component.cardIconCornerRadius : 3))
        .accessibilityHidden(true)
    }

    @ViewBuilder private var cardIconBackground: some View {
        if let color = style.component.cardIconBackgroundColor {
            RoundedRectangle(cornerRadius: style.component.cardIconCornerRadius).fill(Color(uiColor: color))
        }
    }

    private func fallbackGlyph(for summary: FiSummary) -> some View {
        Image(systemName: summary.type.uppercased() == "BANK" ? "building.columns" : "creditcard")
            .resizable()
            .scaledToFit()
            .foregroundColor(textColor)
            .padding(1)
    }

    private var editButton: some View {
        Button(action: onEdit) {
            Image(systemName: "pencil")
                .resizable()
                .scaledToFit()
                .frame(width: editIconSide, height: editIconSide)
                .foregroundColor(textColor)
                .padding(.leading, 2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Edit payment method")
        .accessibilityHint("Change the funding instrument PayPal will charge")
    }

    // MARK: - Helpers

    private func fiText(for summary: FiSummary) -> String {
        guard let lastDigits = summary.lastDigits, !lastDigits.isEmpty else {
            return summary.label
        }
        // Card art conveys the brand; the text is just the masked last digits.
        return "•• \(lastDigits)"
    }
}

/// The PayPal brand mark: `[badge] PayPal`. Shared by the loaded row and the loading skeleton
/// so the brand stays visible while the FI loads.
struct PayPalBrandCluster: View {

    let style: SavedPaymentMethodViewStyle

    private var textColor: Color {
        Color(uiColor: style.root.textColorBase ?? UIColor(white: 0.133, alpha: 1))
    }

    private var labelFont: Font {
        SavedPaymentMethodFont.font(
            name: style.layout.fontName,
            size: EditFiStyleGuard.labelFontSize(style.layout.labelFontSize),
            weight: .bold
        )
    }

    private var badgeHeight: CGFloat {
        EditFiStyleGuard.labelFontSize(style.layout.labelFontSize)
    }

    var body: some View {
        HStack(spacing: EditFiStyleGuard.logoLabelGap(style.layout.logoLabelGap)) {
            if style.layout.showLogo {
                Image("PayPalBadge", bundle: .uiComponents)
                    .resizable()
                    .scaledToFit()
                    .frame(height: badgeHeight)
                    .padding(6)
                    .accessibilityHidden(true)
            }
            if style.layout.showLabel {
                Text("PayPal")
                    .font(labelFont)
                    .foregroundColor(textColor)
                    .fixedSize()
            }
        }
    }
}
