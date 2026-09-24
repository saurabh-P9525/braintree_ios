import SwiftUI
import XCTest
@testable import BraintreeCore
@testable import BraintreePayPal
@testable import BraintreePayPalSavedPaymentMethod

/// Drives every visual state through `ImageRenderer`, which forces SwiftUI to evaluate each
/// `body`. Layout defects in this component are not reachable from the view model: the
/// accessibility truncation bug fixed in this PR lived entirely inside `EditFIRow`'s layout,
/// and every view model assertion passed while it was present.
@MainActor
final class BTPayPalSavedPaymentMethodView_RenderTests: XCTestCase {

    // MARK: - Helpers

    /// `ImageRenderer` yields nil for zero-sized content, so a non-nil image means SwiftUI
    /// evaluated the whole tree and laid it out with a visible frame.
    @discardableResult
    private func render(
        _ view: some View,
        width: CGFloat = 393,
        typeSize: DynamicTypeSize = .large
    ) throws -> UIImage {
        try XCTUnwrap(rendered(view, width: width, typeSize: typeSize))
    }

    private func rendered(
        _ view: some View,
        width: CGFloat = 393,
        typeSize: DynamicTypeSize = .large
    ) -> UIImage? {
        let renderer = ImageRenderer(
            content: view
                .frame(width: width)
                .dynamicTypeSize(typeSize)
        )
        renderer.scale = 2
        return renderer.uiImage
    }

    private func instrument(
        type: String = "CARD",
        label: String? = "Visa",
        lastDigits: String? = "1234",
        imageURL: String? = nil,
        subtype: String? = nil
    ) throws -> BTPayPalSavedPaymentMethod {
        var json: [String: Any] = ["type": type]
        json["label"] = label
        json["lastDigits"] = lastDigits
        json["imageUrl"] = imageURL
        json["subtype"] = subtype
        return try XCTUnwrap(BTPayPalSavedPaymentMethod(json: BTJSON(value: json)))
    }

    private func creditContent(
        learnMoreText: String? = "Learn more",
        isEmbeddable: Bool = false
    ) -> CreditMessageContent {
        CreditMessageContent(
            message: "Or 4 interest-free payments of $324.50.",
            learnMoreText: learnMoreText,
            learnMoreURL: URL(string: "https://example.com/lander"),
            isEmbeddable: isEmbeddable
        )
    }

    private func row(_ content: EditFIRow.Content) -> EditFIRow {
        EditFIRow(content: content, style: BTPayPalSavedPaymentMethodViewStyle(), onEdit: {})
    }

    // MARK: - Glyph selection

    /// A card with no art and a bank with no art must not render the same glyph.
    func testRender_cardAndBankFallbackGlyphsDiffer() throws {
        let card = try instrument(type: "CARD", label: "Visa", lastDigits: "1234", imageURL: nil)
        let bank = try instrument(type: "BANK", label: "Visa", lastDigits: "1234", imageURL: nil)

        let cardImage = try render(row(.instrument(card))).pngData()
        let bankImage = try render(row(.instrument(bank))).pngData()

        XCTAssertNotEqual(cardImage, bankImage)
    }

    /// Only banks get the bank glyph; an unrecognised type is treated as a card rather than
    /// rendering a third, generic glyph.
    func testRender_unknownTypeFallsBackToTheCardGlyph() throws {
        let unknown = try instrument(type: "SOME_FUTURE_TYPE", label: "Visa", lastDigits: "1234", imageURL: nil)
        let card = try instrument(type: "CARD", label: "Visa", lastDigits: "1234", imageURL: nil)

        let unknownImage = try render(row(.instrument(unknown))).pngData()
        let cardImage = try render(row(.instrument(card))).pngData()

        XCTAssertEqual(unknownImage, cardImage)
    }

    /// Same label and digits, different type. A card renders card art plus "••0000"; PayPal Credit
    /// renders the label alone, so the two must not produce identical output.
    func testRender_payPalCreditDiffersFromACardWithTheSameFields() throws {
        let credit = try instrument(type: "PAYPAL_CREDIT", label: "Pay in 4", lastDigits: "0000")
        let card = try instrument(type: "CARD", label: "Pay in 4", lastDigits: "0000")

        let creditImage = try render(row(.instrument(credit))).pngData()
        let cardImage = try render(row(.instrument(card))).pngData()

        XCTAssertNotEqual(creditImage, cardImage)
    }

    // MARK: - Credit messaging

    /// The three message shapes share one render path, so they are driven from a table.
    func testRender_everyCreditMessageShape() {
        let contents: [(name: String, content: CreditMessageContent)] = [
            ("with learn more", creditContent()),
            ("without learn more", creditContent(learnMoreText: nil)),
            ("embeddable", creditContent(isEmbeddable: true))
        ]

        for entry in contents {
            let row = CreditMessagingRow(
                style: BTPayPalSavedPaymentMethodViewStyle(),
                content: entry.content,
                onLearnMore: {}
            )
            XCTAssertNotNil(rendered(row), entry.name)
        }
    }

    // MARK: - Child rows in isolation

    func testRender_skeletonRow() throws {
        try render(BTPayPalSavedPaymentMethodSkeletonRow(style: BTPayPalSavedPaymentMethodViewStyle()))
    }

    func testRender_creditMessageSkeleton() throws {
        try render(CreditMessageSkeleton())
    }

    func testRender_editFIRow_allContentCases() throws {
        let cases: [EditFIRow.Content] = [
            .instrument(try instrument()),
            .displayOnly(email: "buyer@example.com", isEditable: true),
            .displayOnly(email: "buyer@example.com", isEditable: false),
            .brandOnly
        ]

        for content in cases {
            try render(
                EditFIRow(content: content, style: BTPayPalSavedPaymentMethodViewStyle(), onEdit: {})
            )
        }
    }

    // MARK: - Accessibility layout

    /// `EditFIRow` uses `ViewThatFits` to fall back to a stacked layout. At the largest
    /// accessibility sizes the side-by-side layout no longer fits and the account digits
    /// previously truncated to `··1…`, hiding which card would be charged.
    func testRender_instrumentRow_atEveryDynamicTypeSize() throws {
        let sizes: [DynamicTypeSize] = [
            .xSmall, .large, .xxxLarge,
            .accessibility1, .accessibility3, .accessibility5
        ]

        for size in sizes {
            try render(row(.instrument(try instrument())), typeSize: size)
        }
    }

    func testRender_instrumentRow_atNarrowWidthUsesStackedLayout() throws {
        try render(row(.instrument(try instrument())), width: 200, typeSize: .accessibility5)
    }

    func testRender_longLabelTruncatesWithoutTrapping() throws {
        let fi = try instrument(label: String(repeating: "Very Long Bank Name ", count: 10))
        try render(row(.instrument(fi)), typeSize: .accessibility5)
    }
}
