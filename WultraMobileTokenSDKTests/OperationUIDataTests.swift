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
    
    
    func testPreApprovalWarningResponseLegacy() {
        guard let result = prepareResult(response: preApprovalResponse) else {
            XCTFail("Failed to parse JSON data")
            return
        }
        
        let ui = WMTOperationUIData(
            flipButtons: true,
            blockApprovalOnCall: false,
            preApprovalScreens:
                [.init(
                    type: .warning,
                    heading: "Watch out!",
                    message: "You may become a victim of an attack.",
                    elements: [
                        .init(type: .listItem, text: "You activate a new app and allow access to your accounts"),
                        .init(type: .listItem, text: "Make sure the activation takes place on your device"),
                        .init(type: .listItem, text: "If you have been prompted for this operation in connection with a payment, decline it")
                    ],
                    controls: WMTPreApprovalControls(approve: .init(.slider))
                )],
            postApprovalScreen: nil)
        
        let screens = result.ui?.preApprovalScreens
        XCTAssertEqual(result.ui?.flipButtons, ui.flipButtons)
        XCTAssertEqual(result.ui?.blockApprovalOnCall, ui.blockApprovalOnCall)
        XCTAssertEqual(screens?[0].heading, ui.preApprovalScreens?[0].heading)
        XCTAssertEqual(screens?[0].message, ui.preApprovalScreens?[0].message)
        XCTAssertEqual(screens?[0].elements?.count, 3)
        XCTAssertEqual(screens?[0].elements?[0].text, ui.preApprovalScreens?[0].elements?[0].text)
        XCTAssertEqual(screens?[0].elements?[1].text, ui.preApprovalScreens?[0].elements?[1].text)
        XCTAssertEqual(screens?[0].elements?[2].text, ui.preApprovalScreens?[0].elements?[2].text)
        XCTAssertEqual(screens?[0].message, ui.preApprovalScreens?[0].message)
        XCTAssertEqual(screens?[0].controls?.approve?.type, ui.preApprovalScreens?[0].controls?.approve?.type)
    }
    
    func testPreApprovalUnknownResponse() {
        guard let result = prepareResult(response: preApprovalFutureResponse) else {
            XCTFail("Failed to parse JSON data")
            return
        }
        
        let ui = WMTOperationUIData(
            flipButtons: true,
            blockApprovalOnCall: false,
            preApprovalScreens:
                [.init(
                    type: .unknown,
                    heading: "Future",
                    message: "Future is now, old man"
                )],
            postApprovalScreen: nil)
        
        XCTAssertEqual(result.ui?.preApprovalScreens?[0].type, ui.preApprovalScreens?[0].type)
        XCTAssertEqual(result.ui?.preApprovalScreens?[0].heading, ui.preApprovalScreens?[0].heading)
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
            preApprovalScreens: nil,
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
        XCTAssertNil(result.ui?.preApprovalScreens)
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
            preApprovalScreens: nil,
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
    
    func testPreApprovalScreensResponseWithPreApprovalIgnoredLegacy() {
        guard let result = prepareResult(response: preApprovalScreensResponse) else {
            XCTFail("Failed to parse JSON data")
            return
        }
        
        // New apps: array should be present with 2 screens
        guard let screens = result.ui?.preApprovalScreens, screens.count == 2 else {
            XCTFail("preApprovalScreens missing or has wrong count")
            return
        }
        
        // Screen1 (WARNING)
        let s1 = screens[0]
        XCTAssertEqual(s1.id, "id1")
        XCTAssertEqual(s1.type, .warning)
        XCTAssertEqual(s1.backButton, true)
        XCTAssertEqual(s1.image, "image-label")
        XCTAssertEqual(s1.heading, "Watch out!")
        XCTAssertEqual(s1.message, "You may become a victim of an attack.")
        XCTAssertEqual(s1.controls?.flip, true)
        XCTAssertEqual(s1.controls?.decline?.type, .reject)
        XCTAssertEqual(s1.controls?.decline?.text, "Reject Payment")
        XCTAssertEqual(s1.controls?.approve?.type, .button)
        XCTAssertEqual(s1.controls?.approve?.text, "Approve Payment")
        XCTAssertEqual(s1.controls?.approve?.counter, 10)
        XCTAssertEqual(s1.elements?.count, 3)
        if let e1 = s1.elements?.first as? WMTPreApprovalElementAlert {
            XCTAssertEqual(e1.type, .alert)
            XCTAssertEqual(e1.style, .info)
            XCTAssertEqual(e1.text, "Make sure the activation takes place on your device")
        }
        
        // Screen2 (QR_SCAN)
        let s2 = screens[1]
        XCTAssertEqual(s2.id, "id2")
        XCTAssertEqual(s2.type, .qr)
        XCTAssertNil(s2.backButton)
        XCTAssertNil(s2.image)
        XCTAssertEqual(s2.heading, "Watch out!")
        XCTAssertEqual(s2.message, "You may become a victim of an attack.")
        XCTAssertNil(s2.controls)
        XCTAssertNil(s2.elements)

        // Sanity: top-level flags still parsed
        XCTAssertEqual(result.ui?.flipButtons, true)
        XCTAssertEqual(result.ui?.blockApprovalOnCall, false)
    }
    
    func testLegacyPreApproval() {
        guard let result = prepareResult(response: legacyPreApproval) else {
            XCTFail("Failed to parse JSON data")
            return
        }
        
        let first = result.ui?.preApprovalScreens?.first
        XCTAssertEqual(first?.type, .warning)
        XCTAssertEqual(first?.elements?.map(\.text), ["A","B","C"])
        XCTAssertEqual(first?.controls?.approve?.type, .slider)
        XCTAssertEqual(first?.controls?.approve?.counter, nil)
        XCTAssertEqual(first?.controls?.approve?.text, nil)
    }
    
    func testLegacyEmptyItemsBecomeEmptyElements() {
        let legacyEmptyItems = preApprovalFutureResponse
        let result = prepareResult(response: legacyEmptyItems)
        let first = result?.ui?.preApprovalScreens?.first
        XCTAssertEqual(first?.type, .unknown)
        XCTAssertEqual(first?.elements?.count ?? 0, 0)
    }
    
    func testSingularIsWrappedIntoPlural() {
        guard let result = prepareResult(response: preApprovalResponse) else {
            XCTFail("Failed to parse JSON data")
            return
        }
        let screens = result.ui?.preApprovalScreens
        XCTAssertNotNil(screens)
        XCTAssertEqual(1, screens?.count)
    }

    func testUnknownScreenTypeForwardCompat() {
        let json = """
        {
          "id":"1","name":"n","data":"d","status":"PENDING",
          "operationCreated":"2023-04-25T13:09:52+0000",
          "operationExpires":"2023-04-25T13:14:52+0000",
          "ui":{"preApprovalScreen":{"type":"FUTURE","heading":"Future","message":"Future is now, old man."}},
          "allowedSignatureType":{"type":"2FA","variants":[]},
          "formData":{"title":"t","message":"m","attributes":[]}
        }
        """
        guard let r = prepareResult(response: json) else {
            XCTFail("parse fail"); return
        }
        guard let s = r.ui?.preApprovalScreens?.first else {
            XCTFail("no screen"); return
        }
        XCTAssertEqual(s.type, .unknown)
        XCTAssertEqual(s.heading, "Future")
        XCTAssertEqual(s.message, "Future is now, old man.")
    }

    func testUnknownElementTypeForwardCompat() {
        let json = """
        {
          "id":"1","name":"n","data":"d","status":"PENDING",
          "operationCreated":"2023-04-25T13:09:52+0000",
          "operationExpires":"2023-04-25T13:14:52+0000",
          "ui":{
            "preApprovalScreens":[{
              "type":"WARNING","heading":"H","message":"M",
              "elements":[ {"type":"TOTALLY_NEW","text":"new-kind"} ]
            }]
          },
          "allowedSignatureType":{"type":"2FA","variants":[]},
          "formData":{"title":"t","message":"m","attributes":[]}
        }
        """
        guard let result = prepareResult(response: json) else {
            XCTFail("Failed to parse JSON data")
            return
        }
        XCTAssertNotNil(result.ui?.preApprovalScreens?.first)
        XCTAssertNotNil(result.ui?.preApprovalScreens?.first?.elements?.first)
        XCTAssertEqual(result.ui?.preApprovalScreens?.first?.elements?.first?.text, "new-kind")
    }
    
    func testLegacyEmptyItemsBecomeNilElements() {
        guard let result = prepareResult(response: preApprovalFutureResponse) else {
            XCTFail("parse fail"); return
        }
        let first = result.ui?.preApprovalScreens?.first
        XCTAssertEqual(first?.type, .unknown)
        XCTAssertNil(first?.elements)  // empty items → nil
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
    
    private let preApprovalScreensResponse: String = {
        """
        {
            "id": "74654880-6db9-4b84-9174-386fc5e7d8ab",
            "name": "authorize_payment_preApproval_multi",
            "data": "A1*A100.00EUR*ICZ3855000000003643174999",
            "status": "PENDING",
            "operationCreated": "2023-04-25T13:09:52+0000",
            "operationExpires": "2023-04-25T13:14:52+0000",
            "ui": {
                "flipButtons": true,
                "blockApprovalOnCall": false,
                "preApprovalScreens": [
                    {
                        "id": "id1",
                        "type": "WARNING",
                        "backButton": true,
                        "image": "image-label",
                        "heading": "Watch out!",
                        "message": "You may become a victim of an attack.",
                        "elements": [
                            {
                                "id": "e1",
                                "type": "ALERT",
                                "style": "INFO",
                                "text": "Make sure the activation takes place on your device"
                            },
                            {
                                "id": "e2",
                                "type": "BUTTON",
                                "action": "PHONE",
                                "text": "Call center",
                                "href": "+42012345678"
                            },
                            {
                                "id": "e3",
                                "type": "LISTITEM",
                                "icon": "icon-label",
                                "text": "You activate a new app and allow access to your accounts"
                            }
                        ],
                        "controls": {
                            "flip": true,
                            "decline": { "type": "REJECT", "text": "Reject Payment" },
                            "approve": { "type": "BUTTON", "text": "Approve Payment", "counter": 10 }
                        }
                    },
                    {
                        "id": "id2",
                        "type": "QR_SCAN",
                        "heading": "Watch out!",
                        "message": "You may become a victim of an attack."
                    }
                ],
                "preApprovalScreen": {
                    "type": "QR_SCAN",
                    "heading": "Watch out!",
                    "message": "You may become a victim of an attack.",
                    "items": ["You activate a new app and allow access to your accounts"],
                    "approvalType": null
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
    
    let legacyPreApproval: String = {
        """
        {
            "id": "f68f6e70-a3d8-4616-b138-358e1799599d",
            "name": "authorize_payment_postApproval",
            "data": "A1*A100.00EUR*ICZ3855000000003643174999",
            "status": "PENDING",
            "operationCreated": "2023-04-25T12:29:23+0000",
            "operationExpires": "2023-04-25T12:34:23+0000",
            "ui": {
                "flipButtons": true,
                "blockApprovalOnCall": false,
                "preApprovalScreen": {
                    "type": "WARNING",
                    "heading": "H",
                    "message": "M",
                    "items": [
                        "A",
                        "B",
                        "C"
                    ],
                    "approvalType": "SLIDER"
                }
            },
            "allowedSignatureType": {
                "type": "2FA",
                "variants": [
                    "possession_knowledge",
                    "possession_biometry"
                ]
            },
            "formData": {
                "title": "Payment Approval",
                "message": "Please confirm the payment",
                "attributes": [
                    {
                        "type": "AMOUNT",
                        "id": "operation.amount",
                        "label": "Amount",
                        "amount": 100,
                        "currency": "EUR",
                        "amountFormatted": "100,00",
                        "currencyFormatted": "€"
                    },
                    {
                        "type": "KEY_VALUE",
                        "id": "operation.account",
                        "label": "To Account",
                        "value": "CZ3855000000003643174999"
                    }
                ]
            }
        }
        """
    }()
}
