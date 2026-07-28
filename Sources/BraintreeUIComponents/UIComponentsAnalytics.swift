import Foundation

enum UIComponentsAnalytics {

    // MARK: - Card Fields Events

    static let cardFieldsPresented = "ui-components:card-fields:presented"
    static let cardFieldsValidated = "ui-components:card-fields:validated"

    // MARK: - PayPal Button Events

    static let payPalButtonPresented = "ui-components:paypal-button:presented"
    static let payPalButtonSelected = "ui-components:paypal-button:selected"

    // MARK: - Venmo Button Events

    static let venmoButtonPresented = "ui-components:venmo-button:presented"
    static let venmoButtonSelected = "ui-components:venmo-button:selected"

    // MARK: - Saved Payment Method Events

    static let savedPaymentMethodPresented = "ui-components:saved-payment-method-component:presented"
    static let savedPaymentMethodEditSelected = "ui-components:saved-payment-method-component:edit-selected"
    static let savedPaymentMethodFetchFailed = "ui-components:saved-payment-method-component:sticky-fi:fetch-failed"

    // MARK: - Credit Messaging Events

    static let creditMessagingPresented = "ui-components:saved-payment-method-component:credit-messaging:presented"
    static let creditMessagingSelected = "ui-components:saved-payment-method-component:credit-messaging:selected"
    static let creditMessagingFailed = "ui-components:saved-payment-method-component:credit-messaging:failed"
}
