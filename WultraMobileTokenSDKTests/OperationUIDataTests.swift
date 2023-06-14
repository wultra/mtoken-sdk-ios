//
// Copyright 2023 Wultra s.r.o.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions
// and limitations under the License.
//

import XCTest
@testable import WultraMobileTokenSDK

class OperationUIDataTests: XCTestCase {
    
    
    func testPreApprovalWarningResponse() {
        guard let result = prepareResult(response: preApprovalResponse) else {
            XCTFail("Failed to parse JSON data")
            return
        }
        
        let ui = WMTOperationUIData(
            flipButtons: true,
            blockApprovalOnCall: false,
            preApprovalScreen:
                    .init(
                        type: .warning,
                        heading: "Watch out!",
                        message: "You may become a victim of an attack.",
                        items: [
                            "You activate a new app and allow access to your accounts",
                            "Make sure the activation takes place on your device",
                            "If you have been prompted for this operation in connection with a payment, decline it"
                        ],
                        approvalType: WMTPreApprovalScreenConfirmAction(rawValue: "SLIDER")!),
            postApprovalScreen: nil)
        
        
        XCTAssertEqual(result.ui?.flipButtons, ui.flipButtons)
        XCTAssertEqual(result.ui?.blockApprovalOnCall, ui.blockApprovalOnCall)
        XCTAssertEqual(result.ui?.preApprovalScreen?.type,ui.preApprovalScreen?.type)
        XCTAssertEqual(result.ui?.preApprovalScreen?.heading, ui.preApprovalScreen?.heading)
        XCTAssertEqual((result.ui?.preApprovalScreen)?.items, ui.preApprovalScreen?.items)
        XCTAssertEqual((result.ui?.preApprovalScreen)?.message, ui.preApprovalScreen?.message)
        XCTAssertEqual((result.ui?.preApprovalScreen)?.approvalType, ui.preApprovalScreen?.approvalType)
    }
    
    func testPreApprovalUnknownResponse() {
        guard let result = prepareResult(response: preApprovalFutureResponse) else {
            XCTFail("Failed to parse JSON data")
            return
        }
        
        let ui = WMTOperationUIData(
            flipButtons: true,
            blockApprovalOnCall: false,
            preApprovalScreen:
                    .init(
                        type: .unknown,
                        heading: "Future",
                        message: "Future is now, old man",
                        items: [],
                        approvalType: nil),
            postApprovalScreen: nil)
        
        XCTAssertEqual(result.ui?.preApprovalScreen?.type,ui.preApprovalScreen?.type)
        XCTAssertEqual((result.ui?.preApprovalScreen)?.heading, ui.preApprovalScreen?.heading)
    }
    
    func testPostApprovalGenericResponse() {
        guard let result = prepareGenericPostApproval(response: genericPostApproval) else {
            XCTFail("Failed to parse JSON data")
            return
        }
        
        let generic = WMTPostApprovalScreenGeneric(
            heading: "Thank you for your order",
            message: "You may close the application now.",
            payload: try! WMTJSONValue(jsonData:
            """
                {
                    "nestedMessage": "See you next time.",
                    "integer": 1,
                    "boolean": true,
                    "array": ["firstElement", "secondElement"],
                    "object": {
                        "nestedObject": "stringValue"
                    }
                }
             """.data(using: .utf8)!
            )
        )
        
        XCTAssertEqual(result.heading, generic.heading)
        XCTAssertEqual(result.message, generic.message)
        XCTAssertEqual(result.payload, generic.payload)
        XCTAssertEqual(result.payload["nestedMessage"], .string("See you next time."))
        XCTAssertEqual(result.payload["integer"], .int(1))
        XCTAssertEqual(result.payload["boolean"], .bool(true))
        XCTAssertEqual(result.payload["array"], .array([.string("firstElement"), .string("secondElement")]))
        XCTAssertEqual(result.payload["object"], .object(["nestedObject" : .string("stringValue")])    )
    }
    
    
    func testPostApprovalResponseRedirect() {
        guard let result = prepareResult(response: postApprovalResponseRedirect) else {
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
                        WMTRedirectPostApprovalScreenPayload(
                            text: "Go to the application",
                            url:"https://www.alza.cz/ubiquiti-unifi-ap-6-pro-d7212937.htm",
                            countdown: 5),
                    type: WMTPostApprovalScreen.ScreenType(rawValue: "MERCHANT_REDIRECT")!))
        
        XCTAssertEqual(result.ui?.flipButtons, ui.flipButtons)
        XCTAssertEqual(result.ui?.blockApprovalOnCall, ui.blockApprovalOnCall)
        XCTAssertEqual(result.ui?.preApprovalScreen?.type,ui.preApprovalScreen?.type)
        XCTAssertEqual((result.ui?.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.heading, (ui.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.heading)
        XCTAssertEqual((result.ui?.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.message, (ui.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.message)
        XCTAssertEqual(((result.ui?.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.payload as? WMTRedirectPostApprovalScreenPayload)?.text, ((ui.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.payload as? WMTRedirectPostApprovalScreenPayload)?.text)
        XCTAssertEqual(
            ((result.ui?.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.payload as? WMTRedirectPostApprovalScreenPayload)?.url,
            ((ui.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.payload as? WMTRedirectPostApprovalScreenPayload)?.url
        )
        XCTAssertEqual(
            ((result.ui?.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.payload as? WMTRedirectPostApprovalScreenPayload)?.countdown,
            ((ui.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.payload as? WMTRedirectPostApprovalScreenPayload)?.countdown
        )
    }
    
    func testPostApprovalResponseReview() {
        guard let result = prepareResult(response: postApprovalResponseReview) else {
            XCTFail("Failed to parse JSON data")
            return
        }
        
        let ui = WMTOperationUIData(
            flipButtons: nil,
            blockApprovalOnCall: nil,
            preApprovalScreen: nil,
            postApprovalScreen:
                WMTPostApprovalScreenReview(
                    heading: "Successful",
                    message: "The operation was approved.",
                    payload:
                        WMTReviewPostApprovalScreenPayload(
                            attributes: [
                                WMTOperationAttributeNote(
                                    label: WMTOperationAttribute.AttributeLabel(
                                        id: "1",
                                        value: "test label"
                                    ),
                                    note: "myNote"
                                )
                            ]
                        ),
                    type: WMTPostApprovalScreen.ScreenType(rawValue: "REVIEW")!
                )
        )
        let resultPostApproval = result.ui?.postApprovalScreen as? WMTPostApprovalScreenReview
        let uiPostApproval = ui.postApprovalScreen as? WMTPostApprovalScreenReview
        
        XCTAssertEqual(resultPostApproval?.heading, uiPostApproval?.heading)
        XCTAssertEqual(resultPostApproval?.message, uiPostApproval?.message)
        
        let resultNoteAttribute = (resultPostApproval?.payload as? WMTReviewPostApprovalScreenPayload)?.attributes[0] as? WMTOperationAttributeNote
        let uiNoteAttribute = (uiPostApproval?.payload as? WMTReviewPostApprovalScreenPayload)?.attributes[0] as? WMTOperationAttributeNote
        
        XCTAssertEqual(resultNoteAttribute?.note, uiNoteAttribute?.note)
                       
        let resultAttributeLabel = (((result.ui?.postApprovalScreen as? WMTPostApprovalScreenReview)?.payload as? WMTReviewPostApprovalScreenPayload)?.attributes[0] as? WMTOperationAttributeNote)?.label as? WMTOperationAttribute.AttributeLabel
        let uiAttributeLabel = (((ui.postApprovalScreen as? WMTPostApprovalScreenReview)?.payload as? WMTReviewPostApprovalScreenPayload)?.attributes[0] as? WMTOperationAttributeNote)?.label as? WMTOperationAttribute.AttributeLabel
                       
        XCTAssertEqual(resultAttributeLabel?.id, uiAttributeLabel?.id)
        XCTAssertEqual(resultAttributeLabel?.value, uiAttributeLabel?.value)
    }
    
    
    // MARK: Helpers
    private func prepareResult(response: String) -> WMTUserOperation? {
        let result = try? jsonDecoder.decode(WMTUserOperation.self, from: response.data(using: .utf8)!)
        return result
    }
    
    private func prepareGenericPostApproval(response: String) -> WMTPostApprovalScreenGeneric? {
        let result = try? jsonDecoder.decode(WMTPostApprovalScreenGeneric.self, from: response.data(using: .utf8)!)
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
    
    private let preApprovalFutureResponse: String = {
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
                        "type": "FUTURE",
                        "heading": "Future",
                        "message": "Future is now, old man.",
                        "items": []
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
    
    private let postApprovalResponseRedirect: String = {
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
    
    private let postApprovalResponseReview: String = {
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
                    "type": "REVIEW",
                    "heading": "Successful",
                    "message": "The operation was approved.",
                    "payload": {
                      "attributes": [
                        {
                          "type": "NOTE",
                          "id": "1",
                          "label": "test label",
                          "note": "myNote"
                        }
                      ]
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
    
    private let genericPostApproval: String = {
    """
    {
        "type": "GENERIC",
        "heading": "Thank you for your order",
        "message": "You may close the application now.",
        "payload": {
            "nestedMessage": "See you next time.",
            "integer": 1,
            "boolean": true,
            "array": ["firstElement", "secondElement"],
            "object": {
                "nestedObject": "stringValue"
            }
        }
    }
    """
    }()
}
