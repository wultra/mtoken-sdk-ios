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

import Foundation
import Testing
@testable import WultraMobileTokenSDK

struct OperationUIDataTests {
    
    
    @Test
    func testPreApprovalWarningResponseLegacy() {
        guard let result = prepareResult(response: preApprovalResponse) else {
            Issue.record("Failed to parse JSON data")
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
        #expect(result.ui?.flipButtons == ui.flipButtons)
        #expect(result.ui?.blockApprovalOnCall == ui.blockApprovalOnCall)
        #expect(screens?[0].heading == ui.preApprovalScreens?[0].heading)
        #expect(screens?[0].message == ui.preApprovalScreens?[0].message)
        #expect(screens?[0].elements?.count == 3)
        #expect(screens?[0].elements?[0].text == ui.preApprovalScreens?[0].elements?[0].text)
        #expect(screens?[0].elements?[1].text == ui.preApprovalScreens?[0].elements?[1].text)
        #expect(screens?[0].elements?[2].text == ui.preApprovalScreens?[0].elements?[2].text)
        #expect(screens?[0].message == ui.preApprovalScreens?[0].message)
        #expect(screens?[0].controls?.approve?.type == ui.preApprovalScreens?[0].controls?.approve?.type)
    }
    
    @Test
    func testPreApprovalUnknownResponse() {
        guard let result = prepareResult(response: preApprovalFutureResponse) else {
            Issue.record("Failed to parse JSON data")
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
        
        #expect(result.ui?.preApprovalScreens?[0].type == ui.preApprovalScreens?[0].type)
        #expect(result.ui?.preApprovalScreens?[0].heading == ui.preApprovalScreens?[0].heading)
    }
    
    @Test
    func testPostApprovalGenericResponse() {
        guard let result = prepareGenericPostApproval(response: genericPostApproval) else {
            Issue.record("Failed to parse JSON data")
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
        
        #expect(result.heading == generic.heading)
        #expect(result.message == generic.message)
        #expect(result.payload == generic.payload)
        #expect(result.payload["nestedMessage"] == .string("See you next time."))
        #expect(result.payload["integer"] == .int(1))
        #expect(result.payload["boolean"] == .bool(true))
        #expect(result.payload["array"] == .array([.string("firstElement"), .string("secondElement")]))
        #expect(result.payload["object"] == .object(["nestedObject" : .string("stringValue")]))
    }
    
    
    @Test
    func testPostApprovalResponseRedirect() {
        guard let result = prepareResult(response: postApprovalResponseRedirect) else {
            Issue.record("Failed to parse JSON data")
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
        
        #expect(result.ui?.flipButtons == ui.flipButtons)
        #expect(result.ui?.blockApprovalOnCall == ui.blockApprovalOnCall)
        #expect(result.ui?.preApprovalScreens == nil)
        #expect((result.ui?.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.heading == (ui.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.heading)
        #expect((result.ui?.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.message == (ui.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.message)
        #expect(((result.ui?.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.payload as? WMTRedirectPostApprovalScreenPayload)?.text == ((ui.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.payload as? WMTRedirectPostApprovalScreenPayload)?.text)
        #expect(
            ((result.ui?.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.payload as? WMTRedirectPostApprovalScreenPayload)?.url ==
            ((ui.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.payload as? WMTRedirectPostApprovalScreenPayload)?.url
        )
        #expect(
            ((result.ui?.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.payload as? WMTRedirectPostApprovalScreenPayload)?.countdown ==
            ((ui.postApprovalScreen as? WMTPostApprovalScreenRedirect)?.payload as? WMTRedirectPostApprovalScreenPayload)?.countdown
        )
    }
    
    @Test
    func testPostApprovalResponseReview() {
        guard let result = prepareResult(response: postApprovalResponseReview) else {
            Issue.record("Failed to parse JSON data")
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
        
        #expect(resultPostApproval?.heading == uiPostApproval?.heading)
        #expect(resultPostApproval?.message == uiPostApproval?.message)
        
        let resultNoteAttribute = (resultPostApproval?.payload as? WMTReviewPostApprovalScreenPayload)?.attributes[0] as? WMTOperationAttributeNote
        let uiNoteAttribute = (uiPostApproval?.payload as? WMTReviewPostApprovalScreenPayload)?.attributes[0] as? WMTOperationAttributeNote
        
        #expect(resultNoteAttribute?.note == uiNoteAttribute?.note)
        
        let resultAttributeLabel = (((result.ui?.postApprovalScreen as? WMTPostApprovalScreenReview)?.payload as? WMTReviewPostApprovalScreenPayload)?.attributes[0] as? WMTOperationAttributeNote)?.label as? WMTOperationAttribute.AttributeLabel
        let uiAttributeLabel = (((ui.postApprovalScreen as? WMTPostApprovalScreenReview)?.payload as? WMTReviewPostApprovalScreenPayload)?.attributes[0] as? WMTOperationAttributeNote)?.label as? WMTOperationAttribute.AttributeLabel
        
        #expect(resultAttributeLabel?.id == uiAttributeLabel?.id)
        #expect(resultAttributeLabel?.value == uiAttributeLabel?.value)
    }
    
    @Test
    func testPreApprovalScreensResponseWithPreApprovalIgnoredLegacy() {
        guard let result = prepareResult(response: preApprovalScreensResponse) else {
            Issue.record("Failed to parse JSON data")
            return
        }
        
        // New apps: array should be present with 3 screens
        guard let screens = result.ui?.preApprovalScreens, screens.count == 3 else {
            Issue.record("preApprovalScreens missing or has wrong count")
            return
        }
        
        // Screen1 (WARNING)
        let s1 = screens[0]
        #expect(s1.id == "id1")
        #expect(s1.type == .warning)
        #expect(s1.backButton == true)
        #expect(s1.image == "image-label")
        #expect(s1.heading == "Watch out!")
        #expect(s1.message == "You may become a victim of an attack.")
        #expect(s1.controls?.flip == true)
        #expect(s1.controls?.decline?.type == .reject)
        #expect(s1.controls?.decline?.text == "Reject Payment")
        #expect(s1.controls?.approve?.type == .button)
        #expect(s1.controls?.approve?.text == "Approve Payment")
        #expect(s1.controls?.approve?.counter == 10)
        #expect(s1.elements?.count == 3)
        
        // Alert element (first)
        if let e1 = s1.elements?.first as? WMTPreApprovalElementAlert {
            #expect(e1.type == .alert)
            #expect(e1.style == .info)
            #expect(e1.text == "Make sure the activation takes place on your device")
        }
        
        // Button element (second)
        if let e2 = s1.elements?[1] as? WMTPreApprovalElementButton {
            #expect(e2.type == .button)
            #expect(e2.id == "e2")
            #expect(e2.action == .phone)
            #expect(e2.actionSettings == "REJECT")
            #expect(e2.href == "+42012345678")
            #expect(e2.text == "Call center")
        } else {
            Issue.record("Second element should be WMTPreApprovalElementButton")
        }

        // List item element (third)
        if let e3 = s1.elements?[2] as? WMTPreApprovalElementListItem {
            #expect(e3.type == .listItem)
            #expect(e3.id == "e3")
            #expect(e3.icon == "icon-label")
            #expect(e3.text == "You activate a new app and allow access to your accounts")
        } else {
            Issue.record("Third element should be WMTPreApprovalElementListItem")
        }
        
        // Screen2 (QR_SCAN)
        let s2 = screens[1]
        #expect(s2.id == "id2")
        #expect(s2.type == .qr)
        #expect(s2.backButton == nil)
        #expect(s2.image == nil)
        #expect(s2.heading == "Watch out!")
        #expect(s2.message == "You may become a victim of an attack.")
        #expect(s2.controls == nil)
        #expect(s2.elements == nil)
        
        // Screen3 (Log test of incorrect elements structure)
        let s3 = screens[2]
        #expect(s3.elements == nil)

        // Sanity: top-level flags still parsed
        #expect(result.ui?.flipButtons == true)
        #expect(result.ui?.blockApprovalOnCall == false)
    }
    
    @Test
    func testLegacyPreApproval() {
        guard let result = prepareResult(response: legacyPreApproval) else {
            Issue.record("Failed to parse JSON data")
            return
        }
        
        let first = result.ui?.preApprovalScreens?.first
        #expect(first?.type == .warning)
        #expect(first?.elements?.map(\.text) == ["A","B","C"])
        #expect(first?.controls?.approve?.type == .slider)
        #expect(first?.controls?.approve?.counter == nil)
        #expect(first?.controls?.approve?.text == nil)
    }
    
    @Test
    func testLegacyEmptyItemsBecomeNil() {
        let legacyEmptyItems = preApprovalFutureResponse
        let result = prepareResult(response: legacyEmptyItems)
        let first = result?.ui?.preApprovalScreens?.first
        #expect(first?.type == .unknown)
        #expect(first?.elements == nil)
    }
    
    @Test
    func testSingularIsWrappedIntoPlural() {
        guard let result = prepareResult(response: preApprovalResponse) else {
            Issue.record("Failed to parse JSON data")
            return
        }
        let screens = result.ui?.preApprovalScreens
        #expect(screens != nil)
        #expect(1 == screens?.count)
    }

    @Test
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
            Issue.record("parse fail"); return
        }
        guard let s = r.ui?.preApprovalScreens?.first else {
            Issue.record("no screen"); return
        }
        #expect(s.type == .unknown)
        #expect(s.heading == "Future")
        #expect(s.message == "Future is now, old man.")
    }

    @Test
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
            Issue.record("Failed to parse JSON data")
            return
        }
        #expect(result.ui?.preApprovalScreens?.first != nil)
        #expect(result.ui?.preApprovalScreens?.first?.elements?.first != nil)
        #expect(result.ui?.preApprovalScreens?.first?.elements?.first?.text == "new-kind")
    }
    
    @Test
    func testLegacyEmptyItemsBecomeNilElements() {
        guard let result = prepareResult(response: preApprovalFutureResponse) else {
            Issue.record("parse fail"); return
        }
        let first = result.ui?.preApprovalScreens?.first
        #expect(first?.type == .unknown)
        #expect(first?.elements == nil) // empty items → nil
    }
    
    @Test
    func testPreApprovalScreenMissingHeadingAndMessage() {
        let json = """
        {
          "id":"1","name":"n","data":"d","status":"PENDING",
          "operationCreated":"2023-04-25T13:09:52+0000",
          "operationExpires":"2023-04-25T13:14:52+0000",
          "ui":{
            "preApprovalScreens":[{
              "type":"WARNING"
            }]
          },
          "allowedSignatureType":{"type":"2FA","variants":[]},
          "formData":{"title":"t","message":"m","attributes":[]}
        }
        """
        let result = prepareResult(response: json)
        // Screen decode should fail — heading and message are required
        #expect(result?.ui?.preApprovalScreens == nil)
    }
    
    @Test
    func testPreApprovalScreenWithHeadingAndMessage() {
        let json = """
        {
          "id":"1","name":"n","data":"d","status":"PENDING",
          "operationCreated":"2023-04-25T13:09:52+0000",
          "operationExpires":"2023-04-25T13:14:52+0000",
          "ui":{
            "preApprovalScreens":[{
              "type":"INFO",
              "heading":"Test Heading",
              "message":"Test Message"
            }]
          },
          "allowedSignatureType":{"type":"2FA","variants":[]},
          "formData":{"title":"t","message":"m","attributes":[]}
        }
        """
        guard let result = prepareResult(response: json) else {
            Issue.record("Failed to parse JSON data"); return
        }
        let screen = result.ui?.preApprovalScreens?.first
        #expect(screen != nil)
        #expect(screen?.type == .info)
        #expect(screen?.heading == "Test Heading")
        #expect(screen?.message == "Test Message")
    }
    
    @Test
    func testPreApprovalScreensArraySkipsInvalidKeepsValid() {
        let json = """
        {
          "id":"1","name":"n","data":"d","status":"PENDING",
          "operationCreated":"2023-04-25T13:09:52+0000",
          "operationExpires":"2023-04-25T13:14:52+0000",
          "ui":{
            "preApprovalScreens":[
              {"type":"INFO","heading":"First","message":"First message"},
              {"type":"WARNING"},
              {"type":"INFO","heading":"Third","message":"Third message"}
            ]
          },
          "allowedSignatureType":{"type":"2FA","variants":[]},
          "formData":{"title":"t","message":"m","attributes":[]}
        }
        """
        guard let result = prepareResult(response: json) else {
            Issue.record("Failed to parse JSON data"); return
        }
        let screens = result.ui?.preApprovalScreens
        #expect(screens?.count == 2)
        #expect(screens?[0].heading == "First")
        #expect(screens?[0].message == "First message")
        #expect(screens?[1].heading == "Third")
        #expect(screens?[1].message == "Third message")
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
                                "actionSettings": "REJECT",
                                "text": "Call center",
                                "href": "+42012345678"
                            },
                            {
                                "id": "e3",
                                "type": "LIST_ITEM",
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
                    },
                    {
                        "id": "id3",
                        "type": "WARNING",
                        "heading": "Watch out!",
                        "message": "You may become a victim of an attack.",
                        "elements": {
                            "incorrect": "structure"
                        }
                    },
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
