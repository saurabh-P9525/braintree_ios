import Foundation

#if canImport(BraintreeCore)
import BraintreeCore
#endif

/// The parsed response from `/v2/credit/fetch-presentment-messages`, ready to render natively.
///
/// Maps `messages[0].preferred_message` from the Credit Presentment API. Convenience accessors
/// (`mainText`, `logoURL`, `learnMoreText`, `learnMoreURL`) surface the common render fields; the raw
/// `mainItems` / `actionItems` / `disclaimerItems` arrays preserve full ordering and types.
/// - Warning: This feature is in beta. Its public API may change or be removed in future releases.
public struct BTCreditMessagingResult {

    /// A single content block within the message (mirrors an API `text block`).
    public struct ContentItem {

        /// Content type — "TEXT", "LINK", "IMAGE", or "TEXT_VARIABLE".
        public let type: String

        /// Display text (for TEXT / LINK blocks).
        public let text: String?

        /// Screen-reader text (for symbols/abbreviations or the logo).
        public let alternativeText: String?

        /// Source URL for IMAGE blocks (e.g. the PayPal logo).
        public let sourceURL: URL?

        /// Click URL for LINK / IMAGE blocks (e.g. the "Learn more" analytics URL → 303 to the lander).
        public let clickURL: URL?

        /// Whether a LINK can be embedded in a webview/iframe.
        public let embeddable: Bool?

        init(json: BTJSON) {
            self.type = json["type"].asString() ?? ""
            self.text = json["text"].asString()
            self.alternativeText = json["alternative_text"].asString()
            self.sourceURL = json["source_url"].asURL()
            self.clickURL = json["click_url"].asURL()
            self.embeddable = json["embeddable"].isBool ? json["embeddable"].asBool() : nil
        }
    }

    // MARK: - Public Properties

    /// Unique identifier for the returned message.
    public let messageID: String?

    /// Non-unique message type/template identifier (e.g. "PLLT_MQ_GZ", "GENERIC").
    public let messageType: String?

    /// Core content blocks (logo + copy), in display order.
    public let mainItems: [ContentItem]

    /// Call-to-action blocks (e.g. the "Learn more" link), in display order.
    public let actionItems: [ContentItem]

    /// Legal disclaimer blocks, in display order.
    public let disclaimerItems: [ContentItem]

    /// Tracking beacon to fire when the message is displayed.
    public let impressionURL: URL?

    // MARK: - Convenience accessors (for simple native rendering)

    /// The primary offer copy, e.g. "As low as $26.94/mo." (first TEXT block in `mainItems`).
    public var mainText: String? {
        mainItems.first { $0.type == "TEXT" || $0.type == "TEXT_VARIABLE" }?.text
    }

    /// The logo image URL (first IMAGE block in `mainItems`).
    public var logoURL: URL? {
        mainItems.first { $0.type == "IMAGE" }?.sourceURL
    }

    /// The "Learn more" label (first LINK block in `actionItems`).
    public var learnMoreText: String? {
        actionItems.first { $0.type == "LINK" }?.text
    }

    /// The "Learn more" click URL — load this in a webview to show the CFS lander.
    public var learnMoreURL: URL? {
        actionItems.first { $0.type == "LINK" }?.clickURL
    }

    // MARK: - Init

    /// Parses the top-level API response body. Returns `nil` when no message is present.
    init?(json: BTJSON?) {
        guard
            let json,
            let preferred = json["messages"].asArray()?.first?["preferred_message"],
            !preferred.isError,
            preferred.isObject
        else {
            return nil
        }

        self.messageID = preferred["id"].asString()
        self.messageType = preferred["type"].asString()
        self.impressionURL = preferred["analytics"]["impression_url"].asURL()

        let content = preferred["content"]
        self.mainItems = (content["main_items"].asArray() ?? []).map { ContentItem(json: $0) }
        self.actionItems = (content["action_items"].asArray() ?? []).map { ContentItem(json: $0) }
        self.disclaimerItems = (content["disclaimer_items"].asArray() ?? []).map { ContentItem(json: $0) }
    }
}
