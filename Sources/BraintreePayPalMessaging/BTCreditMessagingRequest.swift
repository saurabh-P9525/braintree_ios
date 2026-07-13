import Foundation

/// The POST body for `/v2/credit/fetch-presentment-messages` (BNPL upstream credit messaging).
///
/// Used by `BTCreditMessagingClient` to fetch amount-aware credit messaging (e.g. "As low as $X/mo.")
/// directly from the device, rendering the response natively (HLD Approach 2).
/// - Warning: This feature is in beta. Its public API may change or be removed in future releases.
public struct BTCreditMessagingRequest: Encodable {

    // MARK: - Public Properties

    /// The monetary amount used to calculate the offer (e.g. "500.00"). Optional — the API can return generic copy without it.
    let amount: String?

    /// 3-character ISO-4217 currency code. Defaults to "USD".
    let currencyCode: String

    /// The page/view where the message is shown (maps to `flow_context.page_type`).
    let pageType: String?

    /// When `true`, the returned logo is placed inline within the main text (maps to `content_attributes: ["INLINE_LOGO"]`).
    let inlineLogo: Bool

    // MARK: - Initializer

    /// Creates a `BTCreditMessagingRequest`.
    /// - Parameters:
    ///   - amount: Optional monetary amount used to calculate the offer (e.g. "500.00").
    ///   - currencyCode: 3-character ISO-4217 currency code. Defaults to "USD".
    ///   - pageType: Optional page/view type (e.g. "CHECKOUT", "PRODUCT_DETAILS").
    ///   - inlineLogo: Whether to request the logo inline within the main text. Defaults to `false`.
    public init(
        amount: String? = nil,
        currencyCode: String = "USD",
        pageType: String? = nil,
        inlineLogo: Bool = false
    ) {
        self.amount = amount
        self.currencyCode = currencyCode
        self.pageType = pageType
        self.inlineLogo = inlineLogo
    }

    // MARK: - Encodable

    enum CodingKeys: String, CodingKey {
        case messagePlacements = "message_placements"
        case flowContext = "flow_context"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode([MessagePlacement(request: self)], forKey: .messagePlacements)
        try container.encode(FlowContext(request: self), forKey: .flowContext)
    }

    // MARK: - Body sub-structures

    private struct MessagePlacement: Encodable {

        let amount: Amount?
        let contentAttributes: [String]?

        enum CodingKeys: String, CodingKey {
            case amount
            case contentAttributes = "content_attributes"
        }

        init(request: BTCreditMessagingRequest) {
            if let value = request.amount {
                self.amount = Amount(value: value, currencyCode: request.currencyCode)
            } else {
                self.amount = nil
            }
            self.contentAttributes = request.inlineLogo ? ["INLINE_LOGO"] : nil
        }

        struct Amount: Encodable {

            let value: String
            let currencyCode: String

            enum CodingKeys: String, CodingKey {
                case value
                case currencyCode = "currency_code"
            }
        }
    }

    private struct FlowContext: Encodable {

        // Fixed for the BT Native iOS SDK integration (see Upstream Messaging API V2 Dev Docs).
        let channel = "MOBILE_APP"
        let flowSpecifier = "PURCHASE"
        let attributes = ["BRAND_BRAINTREE", "EXPERIENCE_IOS_SDK"]
        let pageType: String?

        enum CodingKeys: String, CodingKey {
            case channel
            case flowSpecifier = "flow_specifier"
            case attributes
            case pageType = "page_type"
        }

        init(request: BTCreditMessagingRequest) {
            self.pageType = request.pageType
        }
    }
}
