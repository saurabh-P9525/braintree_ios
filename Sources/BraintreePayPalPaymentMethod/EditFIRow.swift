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
    let style: SavedPayPalPaymentMethodViewStyle
    let onEdit: () -> Void

    // MARK: - Layout constants

    private let fiInnerSpacing: CGFloat = 8
    private let cardArtWidth: CGFloat = 30
    private let cardArtHeight: CGFloat = 20

    // MARK: - Derived style values (guarded)

    private var textColor: Color {
        Color(uiColor: style.theme.textColorBase ?? UIColor(white: 0.133, alpha: 1))
    }

    private var fiFont: Font {
        SavedPayPalPaymentMethodFont.font(
            name: style.theme.fontName,
            size: EditFiStyleGuard.fiTextFontSize(style.container.fiCluster.textFontSize)
        )
    }

    private var editIconSide: CGFloat {
        EditFiStyleGuard.editIconSize(style.container.fiCluster.editIconSize)
    }

    private var fiClusterGap: CGFloat {
        EditFiStyleGuard.fiClusterLeadingGap(style.container.fiCluster.leadingGap)
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
                .padding(.leading, fiClusterGap)
            case .displayOnly(let email):
                fiPill {
                    Text(email)
                        .font(fiFont)
                        .foregroundColor(textColor)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    editButton
                }
                .padding(.leading, fiClusterGap)
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
        .padding(EditFiStyleGuard.fiClusterPadding(style.container.fiCluster.padding))
        .background(pillBackground)
    }

    @ViewBuilder private var pillBackground: some View {
        if let color = style.container.fiCluster.backgroundColor {
            RoundedRectangle(cornerRadius: EditFiStyleGuard.fiClusterCornerRadius(style.container.fiCluster.cornerRadius))
                .fill(Color(uiColor: color))
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
        .clipShape(RoundedRectangle(cornerRadius: style.container.fiCluster.cardIconCornerRadius > 0 ? style.container.fiCluster.cardIconCornerRadius : 3))
        .accessibilityHidden(true)
    }

    @ViewBuilder private var cardIconBackground: some View {
        if let color = style.container.fiCluster.cardIconBackgroundColor {
            RoundedRectangle(cornerRadius: style.container.fiCluster.cardIconCornerRadius).fill(Color(uiColor: color))
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

    let style: SavedPayPalPaymentMethodViewStyle

    private var textColor: Color {
        Color(uiColor: style.theme.textColorBase ?? UIColor(white: 0.133, alpha: 1))
    }

    private var labelFont: Font {
        SavedPayPalPaymentMethodFont.font(
            name: style.theme.fontName,
            size: EditFiStyleGuard.labelFontSize(style.container.label.fontSize),
            weight: .bold
        )
    }

    private var badgeHeight: CGFloat {
        EditFiStyleGuard.labelFontSize(style.container.label.fontSize)
    }

    var body: some View {
        HStack(spacing: EditFiStyleGuard.labelLeadingGap(style.container.label.leadingGap)) {
            if style.showLogo {
                Image("PayPalBadge", bundle: .payPalPaymentMethod)
                    .resizable()
                    .scaledToFit()
                    .frame(width: style.container.logo.width.map { EditFiStyleGuard.logoWidth($0) })
                    .frame(height: badgeHeight)
                    .padding(6)
                    .accessibilityHidden(true)
            }
            if style.showLabel {
                Text("PayPal")
                    .font(labelFont)
                    .foregroundColor(textColor)
                    .fixedSize()
            }
        }
    }
}
