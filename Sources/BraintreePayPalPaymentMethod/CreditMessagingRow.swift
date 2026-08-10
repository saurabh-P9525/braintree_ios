import SwiftUI
import UIKit

/// The inline credit (Pay Later) messaging line rendered below the FI row when the request
/// sets `showCreditMessage` and the style keeps messaging enabled.
///
/// The copy comes from `CreditMessagingStyle` today (placeholder text); when the API is
/// wired in it is replaced by the fetched offer's content blocks. Tapping "Learn more"
/// presents the lander (`click_url` webview).
struct CreditMessagingRow: View {

    let style: SavedPayPalPaymentMethodViewStyle
    let onLearnMore: () -> Void

    private var textColor: Color {
        Color(uiColor: style.root.textColorBase ?? UIColor(white: 0.133, alpha: 1))
    }

    /// Accent for "Learn more". When no `primaryColor` is set, the link is distinguished by
    /// bold + underline in the base text color instead (styling doc §3.1).
    private var learnMoreColor: Color? {
        style.root.primaryColor.map { Color(uiColor: $0) }
    }

    private var font: Font {
        SavedPayPalPaymentMethodFont.font(
            name: style.layout.fontName,
            size: EditFiStyleGuard.creditMessageFontSize(style.creditMessaging.fontSize)
        )
    }

    var body: some View {
        // "Learn more" flows inline right after the message and wraps with it (matching design).
        let message = Text(style.creditMessaging.messageText + " ")
            .foregroundColor(textColor)
        let learnMore = Text(style.creditMessaging.learnMoreText)
            .fontWeight(.semibold)
            .underline(learnMoreColor == nil)
            .foregroundColor(learnMoreColor ?? textColor)

        return (message + learnMore)
            .font(font)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture { onLearnMore() }
            .accessibilityElement()
            .accessibilityLabel("\(style.creditMessaging.messageText) \(style.creditMessaging.learnMoreText)")
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Opens Pay Later details")
    }
}
