import Foundation

#if canImport(BraintreeCore)
import BraintreeCore
#endif

/// Reads the payment method ID JWT that the Braintree gateway embeds in a client token generated with a payment method ID.
///
/// `BTClientToken` is internal to `BraintreeCore`, so the raw authorization string is decoded here instead.
enum PaymentMethodIDJWTDecoder {

    /// - Parameter clientToken: The raw client token string, base64 encoded for versions 2 and 3 or UTF-8 JSON for version 1.
    static func decode(clientToken: String) -> String? {
        guard let data = Data(base64Encoded: clientToken) ?? clientToken.data(using: .utf8) else {
            return nil
        }

        return BTJSON(data: data)["paymentMethodIdJwt"].asString()
    }
}
