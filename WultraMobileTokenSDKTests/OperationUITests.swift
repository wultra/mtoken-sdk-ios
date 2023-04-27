//
//  OperationUITests.swift
//  WultraMobileTokenSDKTests
//
//  Created by Marek Stránský on 25.04.2023.
//  Copyright © 2023 Wultra. All rights reserved.
//

import XCTest
@testable import WultraMobileTokenSDK

final class OperationUITests: XCTestCase {

    
    func test_operationPreScreenUIResponse_matchesPreApprovalResponse() {
        
        guard let result = prepareResult(response: preApprovalResponse) else {
            XCTFail("Failed to parse JSON data")
            return
        }
        
        let ui = WMTOperationUIData(
            flipButtons: true,
            blockApprovalOnCall: false,
            preApprovalScreen:
                WMTPreApprovalScreenWarning(
                    heading: "Watch out!",
                    message: "You may become a victim of an attack.",
                    items: ["You activate a new app and allow access to your accounts",
                            "Make sure the activation takes place on your device",
                            "If you have been prompted for this operation in connection with a payment, decline it"],
                    approvalType: PreApprovalScreenConfirmAction(rawValue: "SLIDER")!,
                    type: WMTPreApprovalScreen.PreApprovalScreenType(rawValue: "WARNING")!),
            postApprovalScreen: nil)
        
        
        XCTAssertEqual(result.ui?.flipButtons, ui.flipButtons)
        XCTAssertEqual(result.ui?.blockApprovalOnCall, ui.blockApprovalOnCall)
        XCTAssertEqual(result.ui?.preApprovalScreen?.type,ui.preApprovalScreen?.type)
        XCTAssertEqual((result.ui?.preApprovalScreen as? WMTPreApprovalScreenWarning)?.heading, (ui.preApprovalScreen as? WMTPreApprovalScreenWarning)?.heading)
        XCTAssertEqual((result.ui?.preApprovalScreen as? WMTPreApprovalScreenWarning)?.items, (ui.preApprovalScreen as? WMTPreApprovalScreenWarning)?.items)
        XCTAssertEqual((result.ui?.preApprovalScreen as? WMTPreApprovalScreenWarning)?.message, (ui.preApprovalScreen as? WMTPreApprovalScreenWarning)?.message)
        XCTAssertEqual((result.ui?.preApprovalScreen as? WMTPreApprovalScreenWarning)?.approvalType, (ui.preApprovalScreen as? WMTPreApprovalScreenWarning)?.approvalType)
    }
    
    
    func test_operationPostScreenUIResponse_matchesPostApprovalResponse() {
        
        guard let result = prepareResult(response: postApprovalResponse) else {
            XCTFail("Failed to parse JSON data")
            return
        }
        
        let ui = WMTOperationUIData(
            flipButtons: nil,
            blockApprovalOnCall: nil,
            preApprovalScreen: nil,
            postApprovalScreen:
                WMTPostApprovalScreenRedirect(
                    heading: "Thank you for your order",
                    message: "You will be redirected to the merchant application.",
                    payload:
                        RedirectPostApprovalScreenPayload(
                            text: "Go to the application",
                            url:"https://www.alza.cz/ubiquiti-unifi-ap-6-pro-d7212937.htm",
                            countdown: 5),
                    type: WMTPostApprovalScreen.PostApprovalScreenType(rawValue: "MERCHANT_REDIRECT")!))
        
        XCTAssertEqual(result.ui?.flipButtons, ui.flipButtons)
        XCTAssertEqual(result.ui?.blockApprovalOnCall, ui.blockApprovalOnCall)
        XCTAssertEqual(result.ui?.preApprovalScreen?.type,ui.preApprovalScreen?.type)
        XCTAssertEqual((result.ui?.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.heading, (ui.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.heading)
        XCTAssertEqual((result.ui?.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.heading, (ui.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.heading)
        XCTAssertEqual((result.ui?.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.message, (ui.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.message)
        XCTAssertEqual(((result.ui?.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.payload as? RedirectPostApprovalScreenPayload)?.text, ((ui.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.payload as? RedirectPostApprovalScreenPayload)?.text)
        XCTAssertEqual(
            ((result.ui?.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.payload as? RedirectPostApprovalScreenPayload)?.text,
            ((ui.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.payload as? RedirectPostApprovalScreenPayload)?.text
        )
        XCTAssertEqual(
            ((result.ui?.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.payload as? RedirectPostApprovalScreenPayload)?.url,
            ((ui.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.payload as? RedirectPostApprovalScreenPayload)?.url
        )
        XCTAssertEqual(
            ((result.ui?.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.payload as? RedirectPostApprovalScreenPayload)?.countdown,
            ((ui.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.payload as? RedirectPostApprovalScreenPayload)?.countdown
        )
    }
    
    
    // MARK: Helpers
    
    private func prepareResult(response: String) -> WMTUserOperation? {
        let result = try? jsonDecoder.decode(WMTUserOperation.self, from: response.data(using: .utf8)!)
        return result
    }
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private let preApprovalResponse: String = {
    """
            {
                "id": "74654880-6db9-4b84-9174-386fc5e7d8ab",
                "name": "authorize_payment_preApproval",
                "data": "A1*A100.00EUR*ICZ3855000000003643174999",
                "status": "PENDING",
                "operationCreated": "2023-04-25T13:09:52+0000",
                "operationExpires": "2023-04-25T13:14:52+0000",
                "ui": {
                    "flipButtons": true,
                    "blockApprovalOnCall": false,
                    "preApprovalScreen": {
                        "type": "WARNING",
                        "heading": "Watch out!",
                        "message": "You may become a victim of an attack.",
                        "items": ["You activate a new app and allow access to your accounts", "Make sure the activation takes place on your device", "If you have been prompted for this operation in connection with a payment, decline it"],
                        "approvalType": "SLIDER"
                    }
                },
                "allowedSignatureType": {
                    "type": "2FA",
                    "variants": ["possession_knowledge", "possession_biometry"]
                },
                "formData": {
                    "title": "Payment Approval",
                    "message": "Please confirm the payment",
                    "attributes": [{
                        "type": "AMOUNT",
                        "id": "operation.amount",
                        "label": "Amount",
                        "amount": 100.00,
                        "currency": "EUR",
                        "amountFormatted": "100,00",
                        "currencyFormatted": "€"
                    }, {
                        "type": "KEY_VALUE",
                        "id": "operation.account",
                        "label": "To Account",
                        "value": "CZ3855000000003643174999"
                    }]
                }
            }
    """
    }()
    
    private let postApprovalResponse: String = {
    """
            {
                "id": "f68f6e70-a3d8-4616-b138-358e1799599d",
                "name": "authorize_payment_postApproval",
                "data": "A1*A100.00EUR*ICZ3855000000003643174999",
                "status": "PENDING",
                "operationCreated": "2023-04-25T12:29:23+0000",
                "operationExpires": "2023-04-25T12:34:23+0000",
                "ui": {
                    "postApprovalScreen": {
                        "type": "MERCHANT_REDIRECT",
                        "heading": "Thank you for your order",
                        "message": "You will be redirected to the merchant application.",
                        "payload": {
                            "redirectText": "Go to the application",
                            "redirectUrl": "https://www.alza.cz/ubiquiti-unifi-ap-6-pro-d7212937.htm",
                            "countdown": 5
                        }
                    }
                },
                "allowedSignatureType": {
                    "type": "2FA",
                    "variants": ["possession_knowledge", "possession_biometry"]
                },
                "formData": {
                    "title": "Payment Approval",
                    "message": "Please confirm the payment",
                    "attributes": [{
                        "type": "AMOUNT",
                        "id": "operation.amount",
                        "label": "Amount",
                        "amount": 100.00,
                        "currency": "EUR",
                        "amountFormatted": "100,00",
                        "currencyFormatted": "€"
                    }, {
                        "type": "KEY_VALUE",
                        "id": "operation.account",
                        "label": "To Account",
                        "value": "CZ3855000000003643174999"
                    }]
                }
            }
    """
    }()
}
