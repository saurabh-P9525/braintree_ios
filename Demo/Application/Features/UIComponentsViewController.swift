import UIKit
import SwiftUI
import BraintreeCard
import BraintreeCore
import BraintreeUIComponents
import BraintreePayPalPaymentMethod
import BraintreeVenmo
import BraintreePayPal

class UIComponentsViewController: PaymentButtonBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UI Components"

        let demoView = UIComponentsDemoView(
            authorization: authorization,
            onProgress: { [weak self] message in self?.progressBlock(message) },
            onComplete: { [weak self] nonce in self?.completionBlock(nonce) }
        )

        let hostingController = UIHostingController(rootView: demoView)
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        hostingController.didMove(toParent: self)
    }
}

private struct UIComponentsDemoView: View {

    let authorization: String
    let onProgress: (String?) -> Void
    let onComplete: (BTPaymentMethodNonce?) -> Void

    @State private var isFormValid = false
    @State private var submit: (() -> Void)?
    @State private var venmoColorIndex: Int = 0
    @State private var payPalColorIndex: Int = 0
    @State private var savedFIStateIndex: Int = 1
    @State private var showSavedCreditMessage: Bool = true

    /// Maps the segmented selection to a `SavedPayPalPaymentMethodView` render state. Uses the
    /// public preview initializer so every state is visible before the fetch API is wired.
    private var savedPreviewState: SavedPayPalPaymentMethodPreviewState {
        switch savedFIStateIndex {
        case 0:
            return .loading
        case 1:
            return .instrument(
                FiSummary(
                    type: "CARD",
                    label: "Visa",
                    lastDigits: "0199",
                    imageURL: URL(string: "https://www.paypalobjects.com/ui-web/money-icons/card/visa.png")
                )
            )
        case 2:
            return .instrument(FiSummary(type: "BANK", label: "CREDIT UNION 1", lastDigits: "3357"))
        case 3:
            return .instrument(FiSummary(type: "CARD", label: "A Very Long Funding Instrument Bank Name", lastDigits: "1234"))
        case 4:
            return .displayOnly(email: "buyer@example.com")
        case 5:
            return .brandOnly
        default:
            return .hidden
        }
    }

    private var selectedVenmoColor: VenmoButtonColor {
        switch venmoColorIndex {
        case 1: return .black
        case 2: return .white
        default: return .blue
        }
    }

    private var selectedPayPalColor: PayPalButtonColor {
        switch payPalColorIndex {
        case 1: return .black
        case 2: return .white
        default: return .blue
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Saved Payment Method (Edit FI) — UI-only, state seeded via preview initializer
                VStack(alignment: .leading, spacing: 8) {
                    Text("Saved Payment Method (Edit FI)")
                        .font(.headline)

                    Picker("FI State", selection: $savedFIStateIndex) {
                        Text("Loading").tag(0)
                        Text("Card").tag(1)
                        Text("Bank (no image)").tag(2)
                        Text("Truncation").tag(3)
                        Text("Email only").tag(4)
                        Text("Brand only").tag(5)
                        Text("Hidden").tag(6)
                    }
                    .pickerStyle(.menu)

                    // Demo target defines its own UIKit `Toggle`, so qualify the SwiftUI one.
                    SwiftUI.Toggle("Show credit (Pay Later) message", isOn: $showSavedCreditMessage)
                        .font(.caption)

                    SavedPayPalPaymentMethodView(
                        previewState: savedPreviewState,
                        showCreditMessage: showSavedCreditMessage
                    )
                    .id("\(savedFIStateIndex)-\(showSavedCreditMessage)")
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray.opacity(0.25))
                    )
                }

                Divider()

                // Color toggles
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Venmo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Venmo Color", selection: $venmoColorIndex) {
                            Text("Blue").tag(0)
                            Text("Black").tag(1)
                            Text("White").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("PayPal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("PayPal Color", selection: $payPalColorIndex) {
                            Text("Blue").tag(0)
                            Text("Black").tag(1)
                            Text("White").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                // Card fields
                CardFields(
                    authorization: authorization,
                    card: BTCard()
                ) { nonce, error in
                    if let error {
                        onProgress(error.localizedDescription)
                    } else if let nonce {
                        onComplete(nonce)
                    }
                }
                .onValidityChange { valid, tokenize in
                    isFormValid = valid
                    submit = tokenize
                }

                // Pay button for card fields
                Button("Pay") {
                    onProgress("Tokenizing card...")
                    submit?()
                }
                .disabled(!isFormValid)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isFormValid ? Color.black : Color.black.opacity(0.3))
                .clipShape(Capsule())
                .padding(.horizontal, 8)

                // Venmo + PayPal buttons side by side
                GeometryReader { geo in
                    let buttonWidth = (geo.size.width - 12) / 2
                    HStack(spacing: 12) {
                        VenmoButton(
                            authorization: authorization,
                            // swiftlint:disable:next force_unwrapping
                            universalLink: URL(string: "https://mobile-sdk-demo-site-838cead5d3ab.herokuapp.com/braintree-payments")!,
                            request: BTVenmoRequest(paymentMethodUsage: .singleUse),
                            color: selectedVenmoColor,
                            width: buttonWidth
                        ) { nonce, error in
                            DispatchQueue.main.async {
                                if let nonce {
                                    onProgress("Got a nonce 💎!")
                                    onComplete(nonce)
                                } else if let error {
                                    onProgress((error as? BTVenmoError) == .canceled ? "Canceled 🔰" : error.localizedDescription)
                                }
                            }
                        }

                        PayPalButton(
                            authorization: authorization,
                            // swiftlint:disable:next force_unwrapping
                            universalLink: URL(string: "https://mobile-sdk-demo-site-838cead5d3ab.herokuapp.com/braintree-payments")!,
                            request: BTPayPalCheckoutRequest(
                                amount: "10.00",
                                enablePayPalAppSwitch: true,
                                userAuthenticationEmail: nil,
                                userAction: .payNow
                            ),
                            color: selectedPayPalColor,
                            width: buttonWidth
                        ) { nonce, error in
                            DispatchQueue.main.async {
                                if let nonce {
                                    onProgress("Got a nonce 💎!")
                                    onComplete(nonce)
                                } else if let error {
                                    onProgress((error as? BTPayPalError) == .canceled ? "Canceled 🔰" : error.localizedDescription)
                                }
                            }
                        }
                    }
                }
                .frame(height: 48)
            }
            .padding()
        }
    }
}
