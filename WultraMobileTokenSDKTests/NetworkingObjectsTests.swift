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
    
    func testTokenRequestLegacy() {
        let expectation = """
                          {"requestObject":{"platform":"ios","token":"5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5525"}}
                          """
        let r = WMTPushEndpoints.RegisterDevice.EndpointType.RequestData(WMTPushRegistrationData(platform: .ios, token: "5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5525", environment: nil))
        
        r.testSerialization(expectation: expectation)
    }
    
    func testTokenRequestLegacyWithEnvironment() {
        let expectation = """
                          {"requestObject":{"platform":"ios","token":"5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5525","environment":"development"}}
                          """
        let r = WMTPushEndpoints.RegisterDevice.EndpointType.RequestData(WMTPushRegistrationData(platform: .ios, token: "5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5525", environment: .development))
        
        r.testSerialization(expectation: expectation)
    }
    
    func testTokenRequestApnsDevelopment() {
        let expectation = """
                          {"requestObject":{"platform":"apns","token":"5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5525","environment":"development"}}
                          """
        let r = WMTPushEndpoints.RegisterDevice.EndpointType.RequestData(WMTPushRegistrationData(platform: .apns, token: "5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5525", environment: .development))
        
        r.testSerialization(expectation: expectation)
    }
    
    func testTokenRequestApnsProduction() {
        let expectation = """
                          {"requestObject":{"platform":"apns","token":"5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5525","environment":"production"}}
                          """
        let r = WMTPushEndpoints.RegisterDevice.EndpointType.RequestData(WMTPushRegistrationData(platform: .apns, token: "5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5525", environment: .production))
        
        r.testSerialization(expectation: expectation)
    }
    
    func testTokenRequestFcm() {
        let expectation = """
                          {"requestObject":{"platform":"fcm","token":"bk3RNwTe3H0:CI2k_HHwgIpoDKCIZvvDMExUdFQ3P1"}}
                          """
        let r = WMTPushEndpoints.RegisterDevice.EndpointType.RequestData(WMTPushRegistrationData(platform: .fcm, token: "bk3RNwTe3H0:CI2k_HHwgIpoDKCIZvvDMExUdFQ3P1", environment: nil))
        
        r.testSerialization(expectation: expectation)
    }
    
    func testApnsTokenSerialization() {
        let apnsData = "testData".data(using: .utf8)!
        let expectedApnsHex = "7465737444617461"
        let apns = WMTPushPlatform.apns(token: apnsData, environment: .automatic)
        // data should be transformed to hexformat
        XCTAssertEqual(expectedApnsHex, apns.token)
    }
    
    func testFcmTokenSerialization() {
        let fcmData = "testToken"
        let fcm = WMTPushPlatform.fcm(token: fcmData)
        // FCM token should be the same
        XCTAssertEqual(fcmData, fcm.token)
    }
    
    func testOperationsResponse() {
        let response = """
                       {"status":"OK","currentTimestamp":"2023-02-10T12:30:42+0000","responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3","name":"authorize_payment","data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017","status":"PENDING","operationCreated":"2018-08-08T12:30:42+0000","operationExpires":"2018-08-08T12:35:43+0000","allowedSignatureType":{"type":"2FA","variants":["possession_knowledge", "possession_biometry"]},"formData":{"title":"Potvrzení platby","message":"Dobrý den,prosíme o potvrzení následující platby:","attributes":[{"type":"AMOUNT","id":"operation.amount","label":"Částka","amount":965165234082.23,"currency":"CZK", "valueFormatted": "965165234082.23 CZK"},{"type":"KEY_VALUE","id":"operation.account","label":"Na účet","value":"238400856/0300"},{"type":"KEY_VALUE","id":"operation.dueDate","label":"Datum splatnosti","value":"29.6.2017"},{"type":"NOTE","id":"operation.note","label":"Poznámka","note":"Utility Bill Payment - 05/2017"},{"type":"PARTY_INFO","id":"operation.partyInfo","label":"Application","partyInfo":{"logoUrl":"http://whywander.com/wp-content/uploads/2017/05/prague_hero-100x100.jpg","name":"Tesco","description":"Objevte více příběhů psaných s chutí","websiteUrl":"https://itesco.cz/hello/vse-o-jidle/pribehy-psane-s-chuti/clanek/tomovy-burgery-pro-zapalene-fanousky/15012"}},{ "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmount": 1.26, "sourceCurrency": "ETC", "sourceAmountFormatted": "1.26", "sourceCurrencyFormatted": "ETC", "sourceValueFormatted": "1.26 ETC", "targetAmount": 1710.98, "targetCurrency": "USD", "targetAmountFormatted": "1,710.98", "targetCurrencyFormatted": "USD", "targetValueFormatted": "1,710.98 USD"},{ "type": "IMAGE", "id": "operation.image", "label": "Image", "thumbnailUrl": "https://example.com/123_thumb.jpeg", "originalUrl": "https://example.com/123.jpeg" },{ "type": "IMAGE", "id": "operation.image", "label": "Image", "thumbnailUrl": "https://example.com/123_thumb.jpeg" }]}},{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3","name":"authorize_payment","data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017","status":"PENDING","operationCreated":"2018-08-08T12:30:42+0000","operationExpires":"2018-08-08T12:35:43+0000","allowedSignatureType":{"type":"1FA","variants":["possession_knowledge"]},"formData":{"title":"Potvrzení platby","message":"Dobrý den,prosíme o potvrzení následující platby:","attributes":[{"type":"AMOUNT","id":"operation.amount","label":"Částka","amount":100,"currency":"CZK"},{"type":"KEY_VALUE","id":"operation.account","label":"Na účet","value":"238400856/0300"},{"type":"KEY_VALUE","id":"operation.dueDate","label":"Datum splatnosti","value":"29.6.2017"},{"type":"NOTE","id":"operation.note","label":"Poznámka","note":"Utility Bill Payment - 05/2017"}, {"type": "ALERT","alertType": "WARNING","id": "operation.warning","label": "Balance alert","title": "Nízký zůstatek","message": "Na účtu po platbě zůstane méně než 100 Kč."}, {"type": "ALERT","alertType": "SUCCESS","id": "operation.success","label": "Success alert","message": "Platba byla úspěšně provedena."}]}}]}
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
        
        // Additional tests for the second operation (op2)
        XCTAssertEqual(op2.id, "930febe7-f350-419a-8bc0-c8883e7f71e3")
        XCTAssertEqual(op2.name, "authorize_payment")
        XCTAssertEqual(op2.data, "A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017")
        XCTAssertEqual(op2.status, .pending)
        XCTAssertEqual(op2.operationCreated.timeIntervalSince1970, 1533731442)
        XCTAssertEqual(op2.operationExpires.timeIntervalSince1970, 1533731743)
        XCTAssertEqual(op2.allowedSignatureType.signatureType, .singleFactor)
        XCTAssertEqual(op2.allowedSignatureType.signatureFactors, [.possessionKnowledge])
        XCTAssertEqual(op2.formData.title, "Potvrzení platby")
        XCTAssertEqual(op2.formData.message, "Dobrý den,prosíme o potvrzení následující platby:")
        
        // Test all fields in formData.attributes for op2
        if op2.formData.attributes.count == 6 {
            if let amountAttr = op2.formData.attributes[0] as? WMTOperationAttributeAmount {
                XCTAssertEqual(amountAttr.type, .amount)
                XCTAssertEqual(amountAttr.label.id, "operation.amount")
                XCTAssertEqual(amountAttr.label.value, "Částka")
                XCTAssertEqual(amountAttr.amount, NSDecimalNumber(string: "100").decimalValue)
                XCTAssertEqual(amountAttr.currency, "CZK")
            } else {
                XCTFail("amount attribute not recognized in op2")
            }
            if let accountAttr = op2.formData.attributes[1] as? WMTOperationAttributeKeyValue {
                XCTAssertEqual(accountAttr.type, .keyValue)
                XCTAssertEqual(accountAttr.label.id, "operation.account")
                XCTAssertEqual(accountAttr.label.value, "Na účet")
                XCTAssertEqual(accountAttr.value, "238400856/0300")
            } else {
                XCTFail("account attribute not recognized in op2")
            }
            if let dueDateAttr = op2.formData.attributes[2] as? WMTOperationAttributeKeyValue {
                XCTAssertEqual(dueDateAttr.type, .keyValue)
                XCTAssertEqual(dueDateAttr.label.id, "operation.dueDate")
                XCTAssertEqual(dueDateAttr.label.value, "Datum splatnosti")
                XCTAssertEqual(dueDateAttr.value, "29.6.2017")
            } else {
                XCTFail("dueDate attribute not recognized in op2")
            }
            if let noteAttr = op2.formData.attributes[3] as? WMTOperationAttributeNote {
                XCTAssertEqual(noteAttr.type, .note)
                XCTAssertEqual(noteAttr.label.id, "operation.note")
                XCTAssertEqual(noteAttr.label.value, "Poznámka")
                XCTAssertEqual(noteAttr.note, "Utility Bill Payment - 05/2017")
            } else {
                XCTFail("note attribute not recognized in op2")
            }

            if let alertAttr = op2.formData.attributes[4] as? WMTOperationAttributeAlert {
                XCTAssertEqual(alertAttr.type, .alert)
                XCTAssertEqual(alertAttr.label.id, "operation.warning")
                XCTAssertEqual(alertAttr.alertType, WMTOperationAttributeAlert.AlertType.warning)
                XCTAssertEqual(alertAttr.label.value, "Balance alert")
                XCTAssertEqual(alertAttr.title, "Nízký zůstatek")
                XCTAssertEqual(alertAttr.message, "Na účtu po platbě zůstane méně než 100 Kč.")
            } else {
                XCTFail("alert attribute not recognized in op2")
            }
            
            if let alert2Attr = op2.formData.attributes[5] as? WMTOperationAttributeAlert {
                XCTAssertEqual(alert2Attr.type, .alert)
                XCTAssertEqual(alert2Attr.label.id, "operation.success")
                XCTAssertEqual(alert2Attr.alertType, WMTOperationAttributeAlert.AlertType.success)
                XCTAssertEqual(alert2Attr.label.value, "Success alert")
                XCTAssertNil(alert2Attr.title)
                XCTAssertEqual(alert2Attr.message, "Platba byla úspěšně provedena.")
            } else {
                XCTFail("alert2 attribute not recognized in op2")
            }
            
        } else {
            XCTFail("op2 should contain 6 attributes, but contains \(op2.formData.attributes.count)")
        }
    }
    
    func testOnlyAmountAndConversionAttributesLegacyBackend() {
        let json = """
        {"status":"OK", "currentTimestamp":"2023-02-10T12:30:42+0000", "responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3", "name":"authorize_payment", "status":"PENDING", "data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "operationCreated":"2018-08-08T12:30:42+0000", "operationExpires":"2018-08-08T12:35:43+0000", "allowedSignatureType": {"type":"2FA", "variants": ["possession_knowledge", "possession_biometry"]}, "formData": {"title":"Potvrzení platby", "message":"Dobrý den,prosíme o potvrzení následující platby:", "attributes": [{"type":"AMOUNT", "id":"operation.amount", "label":"Částka", "amount":965165234082.23, "currency":"CZK"}, { "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmount": 1.26, "sourceCurrency": "ETC", "targetAmount": 1710.98, "targetCurrency": "USD"}]}}]}
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
        {"status":"OK", "currentTimestamp":"2023-02-10T12:30:42+0000", "responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3", "name":"authorize_payment", "status":"PENDING", "data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "operationCreated":"2018-08-08T12:30:42+0000", "operationExpires":"2018-08-08T12:35:43+0000", "allowedSignatureType": {"type":"2FA", "variants": ["possession_knowledge", "possession_biometry"]}, "formData": {"title":"Potvrzení platby", "message":"Dobrý den,prosíme o potvrzení následující platby:", "attributes": [{"type":"AMOUNT", "id":"operation.amount", "label":"Částka", "amountFormatted":"965165234082.23", "currencyFormatted":"CZK"}, { "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmountFormatted": "1.26", "sourceCurrencyFormatted": "ETC", "targetAmountFormatted": "1710.98", "targetCurrencyFormatted": "USD"}]}}]}
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
                       {"status":"OK","responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3","name":"authorize_payment","data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017","operationCreated":"2018-08-08T12:30:42+0000","status":"PENDING" ,"operationExpires":"2018-08-08T12:35:43+0000","allowedSignatureType":{"type":"2FA","variants":["possession_knowledge", "possession_biometry"]},"formData":{"title":"Potvrzení platby","message":"Dobrý den,prosíme o potvrzení následující platby:","attributes":[{"type":"THIS_IS_FAKE_ATTR","id":"operation.amount","label":"Částka","amount":965165234082.23,"currency":"CZK"},{"type":"KEY_VALUE","id":"operation.account","label":"Na účet","value":"238400856/0300"}]}}]}
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
        
        let proximityCheckData = WMTProximityCheckData(
            otp: op.proximityCheck!.totp,
            type: op.proximityCheck!.type,
            timestampReceived: op.proximityCheck!.timestampReceived,
            timestampSent: Date()
        )
        let request = WMTOperationEndpoints.Authorize.EndpointType.RequestData(.init(operation: op, adjustedProximityCheck: proximityCheckData))
        
        let proximityCheck = request.requestObject?.proximityCheck
        
        XCTAssertEqual(request.requestObject?.data, "A2")
        XCTAssertEqual(request.requestObject?.id, "47825519-35b8-469d-ad76-e42f85b9a31d")
        XCTAssertEqual(proximityCheck?.type, .qrCode)
        XCTAssertEqual(proximityCheck?.otp, "12345678")
    }
    
    func testMobileTokenDataAuthorizationRequest() {
        // Test creating operation with mobile token data
        let mobileTokenData: [String: Encodable] = [
            "deviceFingerprint": "abc123",
            "riskScore": 0.8,
            "location": [
                "latitude": 50.0755,
                "longitude": 14.4378
            ] as [String: Double]
        ]
        
        // Create a custom test operation with mobile token data
        class TestOperation: WMTOperation {
            let id: String
            let data: String
            let mobileTokenData: [String: Encodable]?
            
            init(id: String, data: String, mobileTokenData: [String: Encodable]?) {
                self.id = id
                self.data = data
                self.mobileTokenData = mobileTokenData
            }
        }
        
        let testOp = TestOperation(id: "test-operation-id", data: "test-operation-data", mobileTokenData: mobileTokenData)
        let request = WMTOperationEndpoints.Authorize.EndpointType.RequestData(.init(operation: testOp))
        
        XCTAssertEqual(request.requestObject?.data, "test-operation-data")
        XCTAssertEqual(request.requestObject?.id, "test-operation-id")
        XCTAssertNotNil(request.requestObject?.mobileTokenData)
        
        // Verify mobile token data content
        if let data = request.requestObject?.mobileTokenData {
            if let deviceFingerprint = data["deviceFingerprint"]?.original as? String {
                XCTAssertEqual(deviceFingerprint, "abc123")
            } else {
                XCTFail("Device fingerprint should be a string")
            }
            
            if let riskScore = data["riskScore"]?.original as? Double {
                XCTAssertEqual(riskScore, 0.8, accuracy: 0.001)
            } else {
                XCTFail("Risk score should be a double")
            }
            
            if let location = data["location"]?.original as? [String: Double] {
                if let lat = location["latitude"] {
                    XCTAssertEqual(lat, 50.0755, accuracy: 0.0001)
                } else {
                    XCTFail("Latitude should be present")
                }
                if let lon = location["longitude"] {
                    XCTAssertEqual(lon, 14.4378, accuracy: 0.0001)
                } else {
                    XCTFail("Longitude should be present")
                }
            } else {
                XCTFail("Location should be a dictionary")
            }
        } else {
            XCTFail("Mobile token data should be present")
        }
        
        // Test operation without mobile token data (backward compatibility)
        let simpleOp = WMTLocalOperation(id: "simple-id", data: "simple-data")
        let simpleRequest = WMTOperationEndpoints.Authorize.EndpointType.RequestData(.init(operation: simpleOp))
        
        XCTAssertEqual(simpleRequest.requestObject?.data, "simple-data")
        XCTAssertEqual(simpleRequest.requestObject?.id, "simple-id")
        XCTAssertNil(simpleRequest.requestObject?.mobileTokenData)
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
        
        guard let result = try? jsonDecoder.decode(WPNResponseArray<WMTUserOperation>.self, from: response.data(using: .utf8)!) else {
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
        WMTUserOperation.Status.allCases.forEach { val in
            XCTAssert(obj.filter({ $0.status == val }).count == 1)
        }
    }
    
    func testAttributesDeserializationNotInterupted() {
        // Non-optional amount removed from AMOUNT Attribute
        let response = """
{"status":"OK", "currentTimestamp":"2023-02-10T12:30:42+0000", "responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3", "name":"authorize_payment", "data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "status":"PENDING", "operationCreated":"2018-08-08T12:30:42+0000", "operationExpires":"2018-08-08T12:35:43+0000", "allowedSignatureType": {"type":"2FA", "variants": ["possession_knowledge", "possession_biometry"]}, "formData": {"title":"Potvrzení platby", "message":"Dobrý den,prosíme o potvrzení následující platby:", "attributes": [{"type":"AMOUNT", "id":"operation.amount", "label":"Částka", "currency":"CZK"}, { "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmount": 1.26, "sourceCurrency": "ETC", "targetAmount": 1710.98, "targetCurrency": "USD"}]}}]}
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
    
    func testResultTexts() {
        let response = """
{"status":"OK", "currentTimestamp":"2023-02-10T12:30:42+0000", "responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3", "name":"authorize_payment", "data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "status": "PENDING", "operationCreated":"2018-08-08T12:30:42+0000", "operationExpires":"2018-08-08T12:35:43+0000", "allowedSignatureType": {"type":"2FA", "variants": ["possession_knowledge", "possession_biometry"]}, "formData": {"title":"Potvrzení platby", "message":"Dobrý den,prosíme o potvrzení následující platby:", "attributes": [{"type":"AMOUNT", "id":"operation.amount", "label":"Částka", "currency":"CZK"}, { "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmount": 1.26, "sourceCurrency": "ETC", "targetAmount": 1710.98, "targetCurrency": "USD"}]}}, {"id":"930febe7-f350-419a-8bc0-c8883e7f71e3", "name":"authorize_payment", "data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "status": "PENDING", "operationCreated":"2018-08-08T12:30:42+0000", "operationExpires":"2018-08-08T12:35:43+0000", "allowedSignatureType": {"type":"2FA", "variants": ["possession_knowledge", "possession_biometry"]}, "formData": {"title":"Potvrzení platby", "message":"Dobrý den,prosíme o potvrzení následující platby:", "resultTexts": {"success": "Payment of was confirmed"}, "attributes": [{"type":"AMOUNT", "id":"operation.amount", "label":"Částka", "currency":"CZK"}, { "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmount": 1.26, "sourceCurrency": "ETC", "targetAmount": 1710.98, "targetCurrency": "USD"}]}}, {"id":"930febe7-f350-419a-8bc0-c8883e7f71e3", "name":"authorize_payment", "data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "status": "PENDING", "operationCreated":"2018-08-08T12:30:42+0000", "operationExpires":"2018-08-08T12:35:43+0000", "allowedSignatureType": {"type":"2FA", "variants": ["possession_knowledge", "possession_biometry"]}, "formData": {"title":"Potvrzení platby", "message":"Dobrý den,prosíme o potvrzení následující platby:", "resultTexts": {"success": "Payment of was confirmed", "reject": "Payment was rejected", "failure": "Payment approval failed"},"attributes": [{"type":"AMOUNT", "id":"operation.amount", "label":"Částka", "currency":"CZK"}, { "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmount": 1.26, "sourceCurrency": "ETC", "targetAmount": 1710.98, "targetCurrency": "USD"}]}}]}
"""
        
        guard let result = try? jsonDecoder.decode(WPNResponseArray<WMTUserOperation>.self, from: response.data(using: .utf8)!) else {
            XCTFail("Failed to parse JSON data")
            return
        }
        
        XCTAssertNil(result.responseObject?[0].formData.resultTexts)
        
        guard let resultTexts1 = result.responseObject?[1].formData.resultTexts else {
            XCTFail("Failed to get resultTexts1")
            return
        }
        
        XCTAssertEqual(resultTexts1.success, "Payment of was confirmed")
        XCTAssertNil(resultTexts1.reject)
        XCTAssertNil(resultTexts1.failure)
        
        guard let resultTexts2 = result.responseObject?[2].formData.resultTexts else {
            XCTFail("Failed to get resultTexts2")
            return
        }
        
        let createdTexts = WMTResultTexts(success: "Payment of was confirmed", failure: "Payment approval failed", reject: "Payment was rejected")
        
        XCTAssertEqual(resultTexts2.success, createdTexts.success)
        XCTAssertEqual(resultTexts2.reject, createdTexts.reject)
        XCTAssertEqual(resultTexts2.failure, createdTexts.failure)
    }
    
    func testOperationWithStatus() {
        let response = """
            {"responseObject":[{"id":"e10bbc25-cf42-4812-815e-3972f49d8f7f","name":"login","data":"A2","status":"CANCELED","operationCreated":"2025-07-29T14:43:33+0000","operationExpires":"2025-07-29T14:48:33+0000","allowedSignatureType":{"type":"2FA","variants":["possession_knowledge","possession_biometry"]},"formData":{"title":"Login Approval","message":"Are you logging in to the internet banking?","attributes":[]}}],"status":"OK","currentTimestamp":"2025-07-29T14:43:36+0000"}
            """
        
        guard let result = try? jsonDecoder.decode(WPNResponseArray<WMTUserOperation>.self, from: response.data(using: .utf8)!).responseObject?[0] else {
            XCTFail("Failed to parse JSON data")
            return
        }
        
        XCTAssertEqual(result.status, .canceled)
    }
    
    func testOperationWithoutStatus() {
        let response = """
            {"responseObject":[{"id":"e10bbc25-cf42-4812-815e-3972f49d8f7f","name":"login","data":"A2","operationCreated":"2025-07-29T14:43:33+0000","operationExpires":"2025-07-29T14:48:33+0000","allowedSignatureType":{"type":"2FA","variants":["possession_knowledge","possession_biometry"]},"formData":{"title":"Login Approval","message":"Are you logging in to the internet banking?","attributes":[]}}],"status":"OK","currentTimestamp":"2025-07-29T14:43:36+0000"}
            """
        
        guard let result = try? jsonDecoder.decode(WPNResponseArray<WMTUserOperation>.self, from: response.data(using: .utf8)!).responseObject?[0] else {
            XCTFail("Failed to parse JSON data")
            return
        }
        
        // when status is missing, defaults to "PENDING"
        XCTAssertEqual(result.status, .pending)
    }
    
    // MARK: - Proximity Check Tests
    
    @Test
    func testProximityCheckInitCapturesCurrentTime() {
        let before = Date()
        let check = WMTProximityCheck(totp: "12345678", type: .qrCode)
        let after = Date()
        
        #expect(check.totp == "12345678")
        #expect(check.type == .qrCode)
        #expect(check.timestampReceived >= before)
        #expect(check.timestampReceived <= after)
    }
    
    @Test
    func testProximityCheckDataTimestampAdjustment() {
        let systemTime = Date()
        let check = WMTProximityCheck(totp: "12345678", type: .deeplink)
        
        // Simulate a +60s localTimeAdjustment (server is 60s ahead of device)
        let adjustment: TimeInterval = 60.0
        let serverTime = Date(timeIntervalSince1970: systemTime.timeIntervalSince1970 + adjustment)
        
        let data = WMTProximityCheckData(
            otp: check.totp,
            type: check.type,
            timestampReceived: check.timestampReceived.addingTimeInterval(adjustment),
            timestampSent: serverTime
        )
        
        // timestampReceived should be shifted by the adjustment
        #expect(abs(data.timestampReceived.timeIntervalSince(check.timestampReceived) - adjustment) < 0.01)
        // timestampSent should be at server time
        #expect(abs(data.timestampSent.timeIntervalSince(serverTime)) < 0.01)
    }
    
    @Test
    func testAuthorizationDataWithoutProximityCheck() {
        let request = WMTOperationEndpoints.Authorize.EndpointType.RequestData(
            .init(operationId: "test-id", operationData: "test-data")
        )
        
        #expect(request.requestObject?.proximityCheck == nil)
        #expect(request.requestObject?.id == "test-id")
        #expect(request.requestObject?.data == "test-data")
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
