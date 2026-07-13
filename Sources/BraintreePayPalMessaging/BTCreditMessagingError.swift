import Foundation

/// Errors returned by `BTCreditMessagingClient`.
/// - Warning: This feature is in beta. Its public API may change or be removed in future releases.
public enum BTCreditMessagingError: Int, Error, CustomNSError, LocalizedError, Equatable {

    /// 0. Invalid authorization type. Credit messaging requires a client token (the `authorizationFingerprint` is used as the Bearer).
    case invalidAuthorization

    /// 1. The Credit Presentment API returned no usable message in the response body.
    case emptyBodyReturned

    public static var errorDomain: String {
        "com.braintreepayments.BTCreditMessagingErrorDomain"
    }

    public var errorCode: Int {
        rawValue
    }

    public var errorDescription: String? {
        switch self {
        case .invalidAuthorization:
            return "Invalid authorization. Credit messaging can only be used with a client token."
        case .emptyBodyReturned:
            return "No credit message was returned from the Credit Presentment API during the request."
        }
    }
}
