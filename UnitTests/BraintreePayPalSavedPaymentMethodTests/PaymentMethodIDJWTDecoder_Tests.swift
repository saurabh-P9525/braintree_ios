import XCTest
@testable import BraintreeTestShared
@testable import BraintreeCore
@testable import BraintreePayPalSavedPaymentMethod

final class PaymentMethodIDJWTDecoder_Tests: XCTestCase {

    func testDecode_whenClientTokenCarriesPaymentMethodIDJWT_returnsJWT() {
        let clientToken = TestClientTokenFactory.token(
            withVersion: 3,
            overrides: ["paymentMethodIdJwt": "fake-payment-method-id-jwt"]
        )

        XCTAssertEqual(PaymentMethodIDJWTDecoder.decode(clientToken: clientToken), "fake-payment-method-id-jwt")
    }

    func testDecode_whenClientTokenIsVersion1UTF8JSON_returnsJWT() {
        let clientToken = TestClientTokenFactory.token(
            withVersion: 1,
            overrides: ["paymentMethodIdJwt": "fake-payment-method-id-jwt"]
        )

        XCTAssertEqual(PaymentMethodIDJWTDecoder.decode(clientToken: clientToken), "fake-payment-method-id-jwt")
    }

    func testDecode_whenClientTokenDoesNotCarryPaymentMethodIDJWT_returnsNil() {
        XCTAssertNil(PaymentMethodIDJWTDecoder.decode(clientToken: TestClientTokenFactory.token(withVersion: 3)))
    }

    func testDecode_whenAuthorizationIsNotAClientToken_returnsNil() {
        XCTAssertNil(PaymentMethodIDJWTDecoder.decode(clientToken: "sandbox_merchant_1234567890abc"))
    }
}
