import Foundation

#if canImport(BraintreeCore)
import BraintreeCore
#endif

/// Use `BTCreditMessagingClient` to fetch BNPL upstream credit messaging (e.g. "As low as $X/mo.")
/// directly from the device via the PayPal Credit Presentment API, and render it natively (HLD Approach 2).
///
/// The call goes to `POST /v2/credit/fetch-presentment-messages` on `api.paypal.com` using the SDK's
/// `.payPalAPI` transport, which authenticates with the client token's `authorizationFingerprint`
/// (`Authorization: Bearer <fingerprint>`). The fingerprint must carry the `client-offer-presentment/read`
/// scope (provisioned on the BT-linked PayPal merchant) — otherwise the API returns `403 NOT_AUTHORIZED`.
///
/// - Warning: This feature is in beta. Its public API may change or be removed in future releases.
///            Only works with a client token.
public class BTCreditMessagingClient {

    // MARK: - Internal Properties

    /// Exposed for testing.
    var apiClient: BTAPIClient

    // MARK: - Initializer

    /// Creates a `BTCreditMessagingClient`.
    /// - Parameter authorization: A valid client token. The embedded `authorizationFingerprint` is used as the Bearer.
    public init(authorization: String) {
        self.apiClient = BTAPIClient(authorization: authorization)
    }

    // MARK: - Public Methods

    /// Fetches credit messaging content for the given request.
    /// - Parameter request: A `BTCreditMessagingRequest` (amount, currency, page type).
    /// - Returns: A `BTCreditMessagingResult` with the content ready to render.
    /// - Throws: `BTCreditMessagingError` or a networking/authorization error (e.g. 403 if the scope is missing).
    public func fetchCreditMessages(_ request: BTCreditMessagingRequest = .init()) async throws -> BTCreditMessagingResult {
        apiClient.sendAnalyticsEvent(BTCreditMessagingAnalytics.fetchStarted)

        // The .payPalAPI transport (Bearer = authorizationFingerprint) is only wired up for client tokens.
        guard apiClient.authorization.type == .clientToken else {
            throw notifyFailure(with: BTCreditMessagingError.invalidAuthorization)
        }

        do {
            let (json, _) = try await apiClient.post(
                "/v2/credit/fetch-presentment-messages",
                parameters: request,
                headers: ["PayPal-Client-Metadata-Id": apiClient.metadata.sessionID],
                httpType: .payPalAPI
            )

            guard let result = BTCreditMessagingResult(json: json) else {
                throw notifyFailure(with: BTCreditMessagingError.emptyBodyReturned)
            }

            apiClient.sendAnalyticsEvent(BTCreditMessagingAnalytics.fetchSucceeded)
            return result
        } catch {
            throw notifyFailure(with: error)
        }
    }

    // MARK: - Analytics Helpers

    private func notifyFailure(with error: Error) -> Error {
        apiClient.sendAnalyticsEvent(
            BTCreditMessagingAnalytics.fetchFailed,
            errorDescription: error.localizedDescription
        )
        return error
    }
}
