//
// Copyright 2020 Wultra s.r.o.
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
import WultraPowerAuthNetworking
@testable import WultraMobileTokenSDK

class NetworkingObjectsTests: XCTestCase {
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testTokenRequest() {
        let expectation = """
                          {"requestObject":{"platform":"ios","token":"5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5525"}}
                          """
        let r = WMTPushEndpoints.RegisterDevice.EndpointType.RequestData(WMTPushRegistrationData(token: "5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5525"))
        
        r.testSerialization(expectation: expectation)
    }
    
    func testOperationsResponse() {
        let response = """
                       {"status":"OK","currentTimestamp":"2023-02-10T12:30:42+0000","responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3","name":"authorize_payment","data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017","operationCreated":"2018-08-08T12:30:42+0000","operationExpires":"2018-08-08T12:35:43+0000","allowedSignatureType":{"type":"2FA","variants":["possession_knowledge", "possession_biometry"]},"formData":{"title":"Potvrzení platby","message":"Dobrý den,prosíme o potvrzení následující platby:","attributes":[{"type":"AMOUNT","id":"operation.amount","label":"Částka","amount":965165234082.23,"currency":"CZK", "valueFormatted": "965165234082.23 CZK"},{"type":"KEY_VALUE","id":"operation.account","label":"Na účet","value":"238400856/0300"},{"type":"KEY_VALUE","id":"operation.dueDate","label":"Datum splatnosti","value":"29.6.2017"},{"type":"NOTE","id":"operation.note","label":"Poznámka","note":"Utility Bill Payment - 05/2017"},{"type":"PARTY_INFO","id":"operation.partyInfo","label":"Application","partyInfo":{"logoUrl":"http://whywander.com/wp-content/uploads/2017/05/prague_hero-100x100.jpg","name":"Tesco","description":"Objevte více příběhů psaných s chutí","websiteUrl":"https://itesco.cz/hello/vse-o-jidle/pribehy-psane-s-chuti/clanek/tomovy-burgery-pro-zapalene-fanousky/15012"}},{ "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmount": 1.26, "sourceCurrency": "ETC", "sourceAmountFormatted": "1.26", "sourceCurrencyFormatted": "ETC", "sourceValueFormatted": "1.26 ETC", "targetAmount": 1710.98, "targetCurrency": "USD", "targetAmountFormatted": "1,710.98", "targetCurrencyFormatted": "USD", "targetValueFormatted": "1,710.98 USD"},{ "type": "IMAGE", "id": "operation.image", "label": "Image", "thumbnailUrl": "https://example.com/123_thumb.jpeg", "originalUrl": "https://example.com/123.jpeg" },{ "type": "IMAGE", "id": "operation.image", "label": "Image", "thumbnailUrl": "https://example.com/123_thumb.jpeg" }]}},{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3","name":"authorize_payment","data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017","operationCreated":"2018-08-08T12:30:42+0000","operationExpires":"2018-08-08T12:35:43+0000","allowedSignatureType":{"type":"1FA","variants":["possession_knowledge"]},"formData":{"title":"Potvrzení platby","message":"Dobrý den,prosíme o potvrzení následující platby:","attributes":[{"type":"AMOUNT","id":"operation.amount","label":"Částka","amount":100,"currency":"CZK"},{"type":"KEY_VALUE","id":"operation.account","label":"Na účet","value":"238400856/0300"},{"type":"KEY_VALUE","id":"operation.dueDate","label":"Datum splatnosti","value":"29.6.2017"},{"type":"NOTE","id":"operation.note","label":"Poznámka","note":"Utility Bill Payment - 05/2017"}]}}]}
                       """
        
        guard let result = try? jsonDecoder.decode(WMTOperationListResponse<WMTUserOperation>.self, from: response.data(using: .utf8)!) else {
            XCTFail("Failed to parse JSON data")
            return
        }
        
        XCTAssertEqual(1676032242, result.currentTimestamp?.timeIntervalSince1970)
        
        XCTAssert(result.status == .Ok)
        XCTAssert(result.responseError == nil)
        
        guard let operations = result.responseObject else {
            XCTFail("response object nil")
            return
        }
        
        guard operations.count == 2 else {
            XCTFail("There should be 2 operations")
            return
        }
        
        let op = operations[0]
        
        XCTAssert(op.id == "930febe7-f350-419a-8bc0-c8883e7f71e3")
        XCTAssert(op.name == "authorize_payment")
        XCTAssert(op.data == "A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017")
        XCTAssertEqual(op.operationCreated.timeIntervalSince1970, 1533731442)
        XCTAssertEqual(op.operationExpires.timeIntervalSince1970, 1533731743)
        XCTAssert(op.allowedSignatureType.signatureType == .twoFactors)
        XCTAssert(op.allowedSignatureType.signatureFactors.contains(.possessionBiometry) && op.allowedSignatureType.signatureFactors.contains(.possessionKnowledge))
        XCTAssert(op.formData.title == "Potvrzení platby")
        XCTAssert(op.formData.message == "Dobrý den,prosíme o potvrzení následující platby:")
        
        if op.formData.attributes.count == 8 {
            
            if let attr = op.formData.attributes[0] as? WMTOperationAttributeAmount {
                XCTAssert(attr.type == .amount)
                XCTAssert(attr.label.id == "operation.amount")
                XCTAssert(attr.label.value == "Částka")
                XCTAssert(attr.amount ==  NSDecimalNumber(string: "965165234082.23").decimalValue)
                XCTAssert(attr.currency == "CZK")
                XCTAssert(attr.valueFormatted == "965165234082.23 CZK")
            } else {
                XCTFail("amount attribute not recognized")
            }
            
            if let attr = op.formData.attributes[1] as? WMTOperationAttributeKeyValue {
                XCTAssert(attr.type == .keyValue)
                XCTAssert(attr.label.id == "operation.account")
                XCTAssert(attr.label.value == "Na účet")
                XCTAssert(attr.value == "238400856/0300")
            } else {
                XCTFail("account attribute not recognized")
            }
            
            if let attr = op.formData.attributes[3] as? WMTOperationAttributeNote {
                XCTAssert(attr.type == .note)
                XCTAssert(attr.label.id == "operation.note")
                XCTAssert(attr.label.value == "Poznámka")
                XCTAssert(attr.note == "Utility Bill Payment - 05/2017")
            } else {
                XCTFail("note attribute not recognized")
            }
            
            if let attr = op.formData.attributes[4] as? WMTOperationAttributePartyInfo {
                XCTAssert(attr.type == .partyInfo)
                XCTAssert(attr.label.id == "operation.partyInfo")
                XCTAssert(attr.label.value == "Application")
                XCTAssert(attr.partyInfo.websiteUrl != nil)
            } else {
                XCTFail("partyInfo attribute not recognized")
            }
            
            if let attr = op.formData.attributes[5] as? WMTOperationAttributeAmountConversion {
                XCTAssert(attr.type == .amountConversion)
                XCTAssert(attr.label.id == "operation.conversion")
                XCTAssert(attr.label.value == "Conversion")
                XCTAssert(attr.dynamic)
                XCTAssert(attr.source.amount == 1.26)
                XCTAssert(attr.source.currency == "ETC")
                XCTAssert(attr.source.amountFormatted == "1.26")
                XCTAssert(attr.source.currencyFormatted == "ETC")
                XCTAssert(attr.source.valueFormatted == "1.26 ETC")
                XCTAssert(attr.target.amount == 1710.98)
                XCTAssert(attr.target.currency == "USD")
                XCTAssert(attr.target.amountFormatted == "1,710.98")
                XCTAssert(attr.target.currencyFormatted == "USD")
                XCTAssert(attr.target.valueFormatted == "1,710.98 USD")
            } else {
                XCTFail("conversion attribute not recognized")
            }
            
            if let attr = op.formData.attributes[6] as? WMTOperationAttributeImage {
                XCTAssert(attr.type == .image)
                XCTAssert(attr.label.id == "operation.image")
                XCTAssert(attr.label.value == "Image")
                XCTAssert(attr.thumbnailUrl == "https://example.com/123_thumb.jpeg")
                XCTAssert(attr.originalUrl == "https://example.com/123.jpeg")
            } else {
                XCTFail("image attribute not recognized")
            }
            
            if let attr = op.formData.attributes[7] as? WMTOperationAttributeImage {
                XCTAssert(attr.type == .image)
                XCTAssert(attr.label.id == "operation.image")
                XCTAssert(attr.label.value == "Image")
                XCTAssert(attr.thumbnailUrl == "https://example.com/123_thumb.jpeg")
                XCTAssert(attr.originalUrl == nil)
            } else {
                XCTFail("image attribute not recognized")
            }
            
            
        } else {
            XCTFail("operation should contain 5 attributes, but contains \(op.formData.attributes.count)")
        }
        
        let op2 = operations[1]
        
        XCTAssert(op2.allowedSignatureType.signatureType == .singleFactor)
        XCTAssert(op2.allowedSignatureType.signatureFactors.count == 1 && op2.allowedSignatureType.signatureFactors.contains(.possessionKnowledge))
    }
    
    func testOnlyAmountAndConversionAttributesLegacyBackend() {
        let json = """
        {"status":"OK", "currentTimestamp":"2023-02-10T12:30:42+0000", "responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3", "name":"authorize_payment", "data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "operationCreated":"2018-08-08T12:30:42+0000", "operationExpires":"2018-08-08T12:35:43+0000", "allowedSignatureType": {"type":"2FA", "variants": ["possession_knowledge", "possession_biometry"]}, "formData": {"title":"Potvrzení platby", "message":"Dobrý den,prosíme o potvrzení následující platby:", "attributes": [{"type":"AMOUNT", "id":"operation.amount", "label":"Částka", "amount":965165234082.23, "currency":"CZK"}, { "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmount": 1.26, "sourceCurrency": "ETC", "targetAmount": 1710.98, "targetCurrency": "USD"}]}}]}
        """
        
        guard let result = try? jsonDecoder.decode(WPNResponseArray<WMTUserOperation>.self, from: json.data(using: .utf8)!) else {
            XCTFail("Failed to parse JSON data")
            return
        }
        
        guard let amountAttr = result.responseObject?[0].formData.attributes[0] as? WMTOperationAttributeAmount  else {
            XCTFail("amount attribute not recognized")
            return
        }
        XCTAssertEqual(Decimal(string: "965165234082.23"), amountAttr.amount)
        XCTAssertEqual("CZK", amountAttr.currency)
        XCTAssertEqual("965165234082.23", amountAttr.amountFormatted)
        XCTAssertEqual("CZK", amountAttr.currencyFormatted)
        
        
        guard let conversionAttr = result.responseObject?[0].formData.attributes[1] as? WMTOperationAttributeAmountConversion else {
            XCTFail("conversion attribute not recognized")
            return
        }
    
        XCTAssertEqual(Decimal(string: "1.26"), conversionAttr.source.amount)
        XCTAssertEqual("ETC", conversionAttr.source.currency)
        XCTAssertEqual(Decimal(string: "1710.98"), conversionAttr.target.amount)
        XCTAssertEqual("USD", conversionAttr.target.currency)
        
        XCTAssertEqual("1.26", conversionAttr.source.amountFormatted)
        XCTAssertEqual("ETC", conversionAttr.source.currencyFormatted)
        XCTAssertEqual("1710.98", conversionAttr.target.amountFormatted)
        XCTAssertEqual("USD", conversionAttr.target.currencyFormatted)
    }

        func testAmountAndConversionAttributesOnlyFormattedValues() {
            let json = """
            {"status":"OK", "currentTimestamp":"2023-02-10T12:30:42+0000", "responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3", "name":"authorize_payment", "data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "operationCreated":"2018-08-08T12:30:42+0000", "operationExpires":"2018-08-08T12:35:43+0000", "allowedSignatureType": {"type":"2FA", "variants": ["possession_knowledge", "possession_biometry"]}, "formData": {"title":"Potvrzení platby", "message":"Dobrý den,prosíme o potvrzení následující platby:", "attributes": [{"type":"AMOUNT", "id":"operation.amount", "label":"Částka", "amountFormatted":"965165234082.23", "currencyFormatted":"CZK"}, { "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmountFormatted": "1.26", "sourceCurrencyFormatted": "ETC", "targetAmountFormatted": "1710.98", "targetCurrencyFormatted": "USD"}]}}]}
            """.trimmingCharacters(in: .whitespacesAndNewlines)

            guard let result = try? jsonDecoder.decode(WPNResponseArray<WMTUserOperation>.self, from: json.data(using: .utf8)!) else {
                XCTFail("Failed to parse JSON data")
                return
            }

            guard let amountAttr = result.responseObject?[0].formData.attributes[0] as? WMTOperationAttributeAmount else {
                XCTFail("amount attribute not recognized")
                return
            }

            XCTAssertNil(amountAttr.amount)
            XCTAssertNil(amountAttr.currency)
            XCTAssertEqual("965165234082.23", amountAttr.amountFormatted)
            XCTAssertEqual("CZK", amountAttr.currencyFormatted)

            guard let conversionAttr = result.responseObject?[0].formData.attributes[1] as? WMTOperationAttributeAmountConversion else {
                XCTFail("conversion attribute not recognized")
                return
            }

            XCTAssertNil(conversionAttr.source.amount)
            XCTAssertNil(conversionAttr.source.currency)
            XCTAssertNil(conversionAttr.target.amount)
            XCTAssertNil(conversionAttr.target.currency)

            XCTAssertEqual("1.26", conversionAttr.source.amountFormatted)
            XCTAssertEqual("ETC", conversionAttr.source.currencyFormatted)
            XCTAssertEqual("1710.98", conversionAttr.target.amountFormatted)
            XCTAssertEqual("USD", conversionAttr.target.currencyFormatted)
        }
    
    func testErrorResponse() {
        
        let response = """
                       {"status":"ERROR","responseObject":{"code":"INVALID_ACTIVATION","message":"Invalid activation found in Mobile Token API component."}}
                       """
        
        guard let result = try? jsonDecoder.decode(WPNResponseArray<WMTUserOperation>.self, from: response.data(using: .utf8)!) else {
            XCTFail("Failed to parse JSON data")
            return
        }
        
        XCTAssert(result.status == .Error)
        XCTAssert(result.responseObject == nil)
        
        guard let error = result.responseError else {
            XCTFail("response error nil")
            return
        }
        
        XCTAssert(error.errorCode == .invalidActivation)
        XCTAssert(error.message == "Invalid activation found in Mobile Token API component.")
    }
    
    func testUnknownAttribute() {
        let response = """
                       {"status":"OK","responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3","name":"authorize_payment","data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017","operationCreated":"2018-08-08T12:30:42+0000","operationExpires":"2018-08-08T12:35:43+0000","allowedSignatureType":{"type":"2FA","variants":["possession_knowledge", "possession_biometry"]},"formData":{"title":"Potvrzení platby","message":"Dobrý den,prosíme o potvrzení následující platby:","attributes":[{"type":"THIS_IS_FAKE_ATTR","id":"operation.amount","label":"Částka","amount":965165234082.23,"currency":"CZK"},{"type":"KEY_VALUE","id":"operation.account","label":"Na účet","value":"238400856/0300"}]}}]}
                       """
        
        guard let result = try? jsonDecoder.decode(WPNResponseArray<WMTUserOperation>.self, from: response.data(using: .utf8)!) else {
            XCTFail("Failed to parse JSON data")
            return
        }
        
        XCTAssert(result.status == .Ok)
        XCTAssert(result.responseError == nil)
        
        guard let operations = result.responseObject else {
            XCTFail("response object nil")
            return
        }
        
        guard operations.count == 1 else {
            XCTFail("There should be 1 operation")
            return
        }
        
        guard operations[0].formData.attributes.count == 2 else {
            XCTFail("There should be 2 attributes")
            return
        }
        
        XCTAssertTrue(operations[0].formData.attributes[0].type == .unknown, "Attribute should be unknown")
    }
    
    func testOperationAuthorizationRequest() {
        
        let expectation = """
                          {"requestObject":{"id":"95e51995-fa60-4018-bd87-43a58f098570","data":"RANDOMDATA"}}
                          """
        let request = WMTOperationEndpoints.Authorize.EndpointType.RequestData(.init(operationId: "95e51995-fa60-4018-bd87-43a58f098570", operationData: "RANDOMDATA"))

        request.testSerialization(expectation: expectation)
    }
    
    func testTOTPOperationAuthorizationRequest() {

        let response = """
                    {"status":"OK","responseObject":[{"id":"47825519-35b8-469d-ad76-e42f85b9a31d","name":"login_preApproval","data":"A2","status":"PENDING","operationCreated":"2023-10-27T11:04:00+0000","operationExpires":"2023-10-27T11:54:00+0000","ui":{"preApprovalScreen":{"type":"QR_SCAN","heading":"Scan the QR code!","message":"To verify that you are close by, please scan the code from the monitor."}},"allowedSignatureType":{"type":"2FA","variants":["possession_knowledge","possession_biometry"]},"formData":{"title":"Login Approval","message":"Are you logging in to the internet banking?","attributes":[]}}],"currentTimestamp":"2023-10-27T11:04:15+0000"}
                    """
        guard let result = try? jsonDecoder.decode(WMTOperationListResponse<WMTUserOperation>.self, from: response.data(using: .utf8)!) else {
            XCTFail("Failed to parse JSON data")
            return
        }
        
        guard let operations = result.responseObject else {
            XCTFail("response object nil")
            return
        }
        
        let op = operations[0]
        op.proximityCheck = WMTProximityCheck(totp: "12345678", type: .qrCode)
        
        let request = WMTOperationEndpoints.Authorize.EndpointType.RequestData(.init(operation: op))
        
        let proximityCheck = request.requestObject?.proximityCheck
        
        XCTAssertEqual(request.requestObject?.data, "A2")
        XCTAssertEqual(request.requestObject?.id, "47825519-35b8-469d-ad76-e42f85b9a31d")
        XCTAssertEqual(proximityCheck?.type, .qrCode)
        XCTAssertEqual(proximityCheck?.otp, "12345678")
    }
    
    func testOperationRejectionRequest() {
        
        let expectation = """
                          {"requestObject":{"id":"95e51995-fa60-4018-bd87-43a58f098570","reason":"COMPLETELLY_CUSTOM_REJECT_REASON"}}
                          """
        
        let request = WMTOperationEndpoints.Reject.EndpointType.RequestData(.init(operationId: "95e51995-fa60-4018-bd87-43a58f098570", reason: .custom("COMPLETELLY_CUSTOM_REJECT_REASON")))
        request.testSerialization(expectation: expectation)
    }
    
    func testHistoryResponse() {
        let response = """
{ "status":"OK", "responseObject":[ { "id":"0775afb2-4f06-4ed9-b990-a35bab4cac3b", "name":"login-tpp", "data":"A2*R666*R123", "status":"PENDING", "operationCreated":"2021-08-09T15:32:24+0000", "operationExpires":"2021-08-09T15:37:24+0000", "allowedSignatureType":{ "type":"2FA", "variants":[ "possession_knowledge", "possession_biometry" ] }, "formData":{ "title":"Login Approval", "message":"Are you logging in to the third party application?", "attributes":[ { "type":"KEY_VALUE", "id":"party.name", "label":"Third Party App", "value":"Datová schránka" }, { "type":"KEY_VALUE", "id":"party.id", "label":"Application ID", "value":"666" }, { "type":"KEY_VALUE", "id":"session.id", "label":"Session ID", "value":"123" }, { "type":"KEY_VALUE", "id":"session.ip-address", "label":"IP Address", "value":"192.168.0.1" } ] } }, { "id":"5bbe1d48-d2f0-43fb-8612-75917a9761fb", "name":"login-tpp", "data":"A2*R666*R123", "status":"REJECTED", "operationCreated":"2021-08-09T15:32:15+0000", "operationExpires":"2021-08-09T15:37:15+0000", "allowedSignatureType":{ "type":"2FA", "variants":[ "possession_knowledge", "possession_biometry" ] }, "formData":{ "title":"Login Approval", "message":"Are you logging in to the third party application?", "attributes":[ { "type":"KEY_VALUE", "id":"party.name", "label":"Third Party App", "value":"Datová schránka" }, { "type":"KEY_VALUE", "id":"party.id", "label":"Application ID", "value":"666" }, { "type":"KEY_VALUE", "id":"session.id", "label":"Session ID", "value":"123" }, { "type":"KEY_VALUE", "id":"session.ip-address", "label":"IP Address", "value":"192.168.0.1" } ] } }, { "id":"8bbff7b6-03c4-470c-9320-4660c3bf1f01", "name":"login-tpp", "data":"A2*R666*R123", "status":"APPROVED", "operationCreated":"2021-08-09T15:31:55+0000", "operationExpires":"2021-08-09T15:36:55+0000", "allowedSignatureType":{ "type":"2FA", "variants":[ "possession_knowledge", "possession_biometry" ] }, "formData":{ "title":"Login Approval", "message":"Are you logging in to the third party application?", "attributes":[ { "type":"KEY_VALUE", "id":"party.name", "label":"Third Party App", "value":"Datová schránka" }, { "type":"KEY_VALUE", "id":"party.id", "label":"Application ID", "value":"666" }, { "type":"KEY_VALUE", "id":"session.id", "label":"Session ID", "value":"123" }, { "type":"KEY_VALUE", "id":"session.ip-address", "label":"IP Address", "value":"192.168.0.1" } ] } }, { "id":"8bbff7b6-03c4-470c-9320-4660c3bf1f01", "name":"login-tpp", "data":"A2*R666*R123", "status":"CANCELED", "operationCreated":"2021-08-09T15:31:55+0000", "operationExpires":"2021-08-09T15:36:55+0000", "allowedSignatureType":{ "type":"2FA", "variants":[ "possession_knowledge", "possession_biometry" ] }, "formData":{ "title":"Login Approval", "message":"Are you logging in to the third party application?", "attributes":[ { "type":"KEY_VALUE", "id":"party.name", "label":"Third Party App", "value":"Datová schránka" }, { "type":"KEY_VALUE", "id":"party.id", "label":"Application ID", "value":"666" }, { "type":"KEY_VALUE", "id":"session.id", "label":"Session ID", "value":"123" }, { "type":"KEY_VALUE", "id":"session.ip-address", "label":"IP Address", "value":"192.168.0.1" } ] } }, { "id":"8bbff7b6-03c4-470c-9320-4660c3bf1f01", "name":"login-tpp", "data":"A2*R666*R123", "status":"EXPIRED", "operationCreated":"2021-08-09T15:31:55+0000", "operationExpires":"2021-08-09T15:36:55+0000", "allowedSignatureType":{ "type":"2FA", "variants":[ "possession_knowledge", "possession_biometry" ] }, "formData":{ "title":"Login Approval", "message":"Are you logging in to the third party application?", "attributes":[ { "type":"KEY_VALUE", "id":"party.name", "label":"Third Party App", "value":"Datová schránka" }, { "type":"KEY_VALUE", "id":"party.id", "label":"Application ID", "value":"666" }, { "type":"KEY_VALUE", "id":"session.id", "label":"Session ID", "value":"123" }, { "type":"KEY_VALUE", "id":"session.ip-address", "label":"IP Address", "value":"192.168.0.1" } ] } }, { "id":"8bbff7b6-03c4-470c-9320-4660c3bf1f01", "name":"login-tpp", "data":"A2*R666*R123", "status":"FAILED", "operationCreated":"2021-08-09T15:31:55+0000", "operationExpires":"2021-08-09T15:36:55+0000", "allowedSignatureType":{ "type":"2FA", "variants":[ "possession_knowledge", "possession_biometry" ] }, "formData":{ "title":"Login Approval", "message":"Are you logging in to the third party application?", "attributes":[ { "type":"KEY_VALUE", "id":"party.name", "label":"Third Party App", "value":"Datová schránka" }, { "type":"KEY_VALUE", "id":"party.id", "label":"Application ID", "value":"666" }, { "type":"KEY_VALUE", "id":"session.id", "label":"Session ID", "value":"123" }, { "type":"KEY_VALUE", "id":"session.ip-address", "label":"IP Address", "value":"192.168.0.1" } ] } } ] }
"""
        
        guard let result = try? jsonDecoder.decode(WPNResponseArray<WMTOperationHistoryEntry>.self, from: response.data(using: .utf8)!) else {
            XCTFail("Failed to parse JSON data")
            return
        }
        
        XCTAssert(result.status == .Ok)
        XCTAssert(result.responseObject != nil)
        
        guard let obj = result.responseObject else {
            XCTFail("response object nil")
            return
        }
        
        // each enum case should be inside the JSON
        WMTOperationHistoryEntry.Status.allCases.forEach { val in
            XCTAssert(obj.filter({ $0.status == val }).count == 1)
        }
    }
    
    func testAttributesDeserializationNotInterupted() {
        // Non-optional amount removed from AMOUNT Attribute
        let response = """
{"status":"OK", "currentTimestamp":"2023-02-10T12:30:42+0000", "responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3", "name":"authorize_payment", "data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "operationCreated":"2018-08-08T12:30:42+0000", "operationExpires":"2018-08-08T12:35:43+0000", "allowedSignatureType": {"type":"2FA", "variants": ["possession_knowledge", "possession_biometry"]}, "formData": {"title":"Potvrzení platby", "message":"Dobrý den,prosíme o potvrzení následující platby:", "attributes": [{"type":"AMOUNT", "id":"operation.amount", "label":"Částka", "currency":"CZK"}, { "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmount": 1.26, "sourceCurrency": "ETC", "targetAmount": 1710.98, "targetCurrency": "USD"}]}}]}
"""

        guard let result = try? jsonDecoder.decode(WPNResponseArray<WMTUserOperation>.self, from: response.data(using: .utf8)!) else {
            XCTFail("Failed to parse JSON data")
            return
        }
        
        guard let attributes = result.responseObject?[0].formData.attributes else {
            XCTFail("Failed to get attributes")
            return
        }
        
        XCTAssertTrue(attributes.count == 1, "There should be one Conversion Attribute but the count is: \(attributes.count)")
        XCTAssert(attributes.first is WMTOperationAttributeAmountConversion, "The First attribute should be a Conversion Attribute.")
    }
}

extension WPNRequestBase {
    
    func testSerialization(expectation: String) {
        
        // Convert WPNRequestBase object to Data
        guard let data = try? JSONEncoder().encode(self) else {
            XCTFail("Failed to encode request data")
            return
        }

        // Convert String to Data
        guard let expectationData = expectation.data(using: .utf8) else {
            XCTFail("Failed to encode expectation string")
            return
        }
        
        // Convert to [String: Any]
        guard let expectationDict = try? JSONSerialization.jsonObject(with: expectationData) as? [String: Any],
               let jsonDataDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            XCTFail("Failed to cast data to format [String: Any]")
            return
        }
        
        // Convert back to data with sorted keys
        guard let sortedExpectationData = try? JSONSerialization.data(withJSONObject: expectationDict, options: [.sortedKeys]),
                let sortedJsonData = try? JSONSerialization.data(withJSONObject: jsonDataDict, options: [.sortedKeys]) else {
            XCTFail("Failed to sort data")
            return
        }
                
        // Convert Data back to strings for comparison
        guard let sortedExpectationString = String(data: sortedExpectationData, encoding: .utf8),
              let sortedJsonDataString = String(data: sortedJsonData, encoding: .utf8) else {
            XCTFail("Failed to cast data to string")
            return
        }
                    
        XCTAssertEqual(sortedExpectationString, sortedJsonDataString, "Serialized Strings doesn't match")
    }
}
