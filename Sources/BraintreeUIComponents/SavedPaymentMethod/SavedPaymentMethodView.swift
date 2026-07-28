import BraintreeCore
import BraintreePayPal
import SwiftUI
import UIKit

/// A drop-in checkout component that shows the returning PayPal buyer's saved funding
/// instrument (FI) and lets them edit it, with optional inline Pay Later messaging.
///
/// The component resolves and renders the sticky FI, exposes an edit affordance that
/// launches the PayPal paysheet, and reports the outcome via `onResult`. The buyer's FI is
/// resolved by the SDK from the client token — the merchant supplies only the checkout
/// request (its amount also drives the credit-messaging line).
///
/// > Note: The fetch/edit network calls are not yet wired in; the component renders its
/// > loading and result states from the view model, which is where those APIs plug in.
public struct SavedPaymentMethodView: View {

    // MARK: - Private Properties

    @StateObject private var viewModel: SavedPaymentMethodViewModel

    private var style: SavedPaymentMethodViewStyle { viewModel.style }

    // MARK: - Initializer

    /// Creates a `SavedPaymentMethodView`.
    /// - Parameters:
    ///   - authorization: Required. A valid client token or tokenization key. The saved FI is
    ///     resolved from the client token.
    ///   - request: Required. The request configuring the component (checkout request + credit-message toggle).
    ///   - style: Optional. Styling overrides. Defaults to the shipped `SavedPaymentMethodViewStyle`.
    ///   - onResult: Called with the terminal `SavedPaymentMethodResult` after an edit flow completes.
    public init(
        authorization: String,
        request: SavedPaymentMethodRequest,
        style: SavedPaymentMethodViewStyle = SavedPaymentMethodViewStyle(),
        onResult: @escaping (SavedPaymentMethodResult) -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: SavedPaymentMethodViewModel(
                request: request,
                style: style,
                onResult: onResult,
                apiClient: BTAPIClient(authorization: authorization)
            )
        )
    }

    /// Internal initializer for previews and tests — seeds a concrete render state.
    init(viewModel: SavedPaymentMethodViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - View

    public var body: some View {
        Group {
            if viewModel.fiState == .hidden {
                EmptyView()
            } else {
                container
            }
        }
        .onAppear { viewModel.onAppear() }
        .sheet(isPresented: $viewModel.isLanderPresented) {
            CreditMessagingLanderView(url: viewModel.learnMoreURL)
        }
    }

    private var container: some View {
        VStack(alignment: .leading, spacing: 8) {
            fiRegion
            creditRegion
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: style.component.height, alignment: .center)
        .padding(.horizontal, style.component.horizontalPadding)
        .padding(.vertical, style.component.verticalPadding)
        .background(Color(uiColor: style.root.backgroundColor ?? .clear))
        .clipShape(RoundedRectangle(cornerRadius: style.component.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: style.component.cornerRadius)
                .stroke(
                    Color(uiColor: style.component.borderColor ?? .clear),
                    lineWidth: style.component.borderWidth
                )
        )
    }

    @ViewBuilder private var fiRegion: some View {
        switch viewModel.fiState {
        case .loading:
            SavedPaymentMethodSkeletonRow(style: style)
        case .instrument(let summary):
            EditFIRow(content: .instrument(summary), style: style) { viewModel.editTapped() }
        case .displayOnly(let email):
            EditFIRow(content: .displayOnly(email: email), style: style) { viewModel.editTapped() }
        case .brandOnly:
            EditFIRow(content: .brandOnly, style: style) { viewModel.editTapped() }
        case .hidden:
            EmptyView()
        }
    }

    @ViewBuilder private var creditRegion: some View {
        if viewModel.request.showCreditMessage, style.creditMessaging.enabled {
            if viewModel.fiState == .loading {
                CreditMessageSkeleton()
            } else {
                CreditMessagingRow(style: style) {
                    viewModel.learnMoreTapped()
                }
            }
        }
    }
}

// MARK: - Preview / Demo support

/// Render-state selector for the demo/preview initializer below.
///
/// - Note: This is a temporary seam for demos, SwiftUI previews, and UI tests while the
///   fetch API is not yet wired. It is expected to be removed once `SavedPaymentMethodView`
///   resolves its own state from the network.
public enum SavedPaymentMethodPreviewState: Equatable {
    case loading
    case instrument(FiSummary)
    case displayOnly(email: String)
    case brandOnly
    case hidden
}

extension SavedPaymentMethodView {

    /// Seeds a concrete render state, bypassing the fetch API (not yet wired). Intended for
    /// demos, SwiftUI previews, and UI tests only.
    ///
    /// - Note: Temporary — remove once the component resolves its state from the network.
    public init(
        previewState: SavedPaymentMethodPreviewState,
        showCreditMessage: Bool = false,
        style: SavedPaymentMethodViewStyle = SavedPaymentMethodViewStyle()
    ) {
        let request = SavedPaymentMethodRequest(
            payPalRequest: BTPayPalCheckoutRequest(amount: "0"),
            showCreditMessage: showCreditMessage
        )
        let fiState: SavedPaymentMethodViewModel.FIState
        switch previewState {
        case .loading:
            fiState = .loading
        case .instrument(let summary):
            fiState = .instrument(summary)
        case .displayOnly(let email):
            fiState = .displayOnly(email: email)
        case .brandOnly:
            fiState = .brandOnly
        case .hidden:
            fiState = .hidden
        }
        self.init(viewModel: SavedPaymentMethodViewModel(previewState: fiState, request: request, style: style))
    }
}

// MARK: - Previews

struct SavedPaymentMethodView_Previews: PreviewProvider {

    private static let request = SavedPaymentMethodRequest(
        payPalRequest: BTPayPalCheckoutRequest(amount: "324.50"),
        showCreditMessage: true
    )

    private static func preview(
        _ title: String,
        _ state: SavedPaymentMethodViewModel.FIState,
        style: SavedPaymentMethodViewStyle = SavedPaymentMethodViewStyle()
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            SavedPaymentMethodView(
                viewModel: SavedPaymentMethodViewModel(previewState: state, request: request, style: style)
            )
            .border(Color.gray.opacity(0.2))
        }
    }

    private static var borderedStyle: SavedPaymentMethodViewStyle {
        var style = SavedPaymentMethodViewStyle()
        style.component.cornerRadius = 8
        style.component.borderColor = .systemGray4
        style.component.borderWidth = 1
        style.component.horizontalPadding = 12
        return style
    }

    static var previews: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                preview("Loading (skeleton)", .loading)
                preview("Instrument — card with art", .instrument(
                    FiSummary(type: "CARD", label: "Visa", lastDigits: "0199",
                              imageURL: URL(string: "https://www.paypalobjects.com/visa.png"))
                ))
                preview("Instrument — no image (fallback glyph)", .instrument(
                    FiSummary(type: "BANK", label: "CREDIT UNION 1", lastDigits: "3357")
                ))
                preview("Instrument — truncation", .instrument(
                    FiSummary(type: "CARD", label: "A Very Long Funding Instrument Bank Name", lastDigits: "1234")
                ))
                preview("Display-only (email)", .displayOnly(email: "buyer@example.com"))
                preview("Brand only (no network)", .brandOnly)
                preview("Bordered container", .instrument(
                    FiSummary(type: "CARD", label: "Mastercard", lastDigits: "4444")
                ), style: borderedStyle)
            }
            .padding()
        }
    }
}
