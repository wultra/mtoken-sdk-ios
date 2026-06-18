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

import Foundation
import Testing
import WultraPowerAuthNetworking
@testable import WultraMobileTokenSDK

struct NetworkingObjectsTests {
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    @Test
    func testTokenRequestApnsDevelopment() {
        let expectation = """
                          {"requestObject":{"platform":"apns","token":"5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5525","environment":"development"}}
                          """
        let r = WMTPushEndpoints.RegisterDevice.EndpointType.RequestData(WMTPushRegistrationData(platform: .apns, token: "5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5525", environment: .development))
        
        r.testSerialization(expectation: expectation)
    }
    
    @Test
    func testTokenRequestApnsProduction() {
        let expectation = """
                          {"requestObject":{"platform":"apns","token":"5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5525","environment":"production"}}
                          """
        let r = WMTPushEndpoints.RegisterDevice.EndpointType.RequestData(WMTPushRegistrationData(platform: .apns, token: "5FBC85D026945C48A17FE1327C68C77F7793FEBFE23FF5850224BEE4215C5525", environment: .production))
        
        r.testSerialization(expectation: expectation)
    }
    
    @Test
    func testTokenRequestFcm() {
        let expectation = """
                          {"requestObject":{"platform":"fcm","token":"bk3RNwTe3H0:CI2k_HHwgIpoDKCIZvvDMExUdFQ3P1"}}
                          """
        let r = WMTPushEndpoints.RegisterDevice.EndpointType.RequestData(WMTPushRegistrationData(platform: .fcm, token: "bk3RNwTe3H0:CI2k_HHwgIpoDKCIZvvDMExUdFQ3P1", environment: nil))
        
        r.testSerialization(expectation: expectation)
    }
    
    @Test
    func testApnsTokenSerialization() {
        let apnsData = "testData".data(using: .utf8)!
        let expectedApnsHex = "7465737444617461"
        let apns = WMTPushPlatform.apns(token: apnsData, environment: .automatic)
        // data should be transformed to hexformat
        #expect(expectedApnsHex == apns.token)
    }
    
    @Test
    func testFcmTokenSerialization() {
        let fcmData = "testToken"
        let fcm = WMTPushPlatform.fcm(token: fcmData)
        // FCM token should be the same
        #expect(fcmData == fcm.token)
    }
    
    @Test
    func testOperationsResponse() {
        let response = """
                       {"status":"OK","currentTimestamp":"2023-02-10T12:30:42+0000","responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3","name":"authorize_payment","data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017","status":"PENDING","operationCreated":"2018-08-08T12:30:42+0000","operationExpires":"2018-08-08T12:35:43+0000","allowedSignatureType":{"type":"2FA","variants":["possession_knowledge", "possession_biometry"]},"formData":{"title":"Potvrzení platby","message":"Dobrý den,prosíme o potvrzení následující platby:","attributes":[{"type":"AMOUNT","id":"operation.amount","label":"Částka","amount":965165234082.23,"currency":"CZK", "valueFormatted": "965165234082.23 CZK"},{"type":"KEY_VALUE","id":"operation.account","label":"Na účet","value":"238400856/0300"},{"type":"KEY_VALUE","id":"operation.dueDate","label":"Datum splatnosti","value":"29.6.2017"},{"type":"NOTE","id":"operation.note","label":"Poznámka","note":"Utility Bill Payment - 05/2017"},{"type":"PARTY_INFO","id":"operation.partyInfo","label":"Application","partyInfo":{"logoUrl":"http://whywander.com/wp-content/uploads/2017/05/prague_hero-100x100.jpg","name":"Tesco","description":"Objevte více příběhů psaných s chutí","websiteUrl":"https://itesco.cz/hello/vse-o-jidle/pribehy-psane-s-chuti/clanek/tomovy-burgery-pro-zapalene-fanousky/15012"}},{ "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmount": 1.26, "sourceCurrency": "ETC", "sourceAmountFormatted": "1.26", "sourceCurrencyFormatted": "ETC", "sourceValueFormatted": "1.26 ETC", "targetAmount": 1710.98, "targetCurrency": "USD", "targetAmountFormatted": "1,710.98", "targetCurrencyFormatted": "USD", "targetValueFormatted": "1,710.98 USD"},{ "type": "IMAGE", "id": "operation.image", "label": "Image", "thumbnailUrl": "https://example.com/123_thumb.jpeg", "originalUrl": "https://example.com/123.jpeg" },{ "type": "IMAGE", "id": "operation.image", "label": "Image", "thumbnailUrl": "https://example.com/123_thumb.jpeg" }]}},{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3","name":"authorize_payment","data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017","status":"PENDING","operationCreated":"2018-08-08T12:30:42+0000","operationExpires":"2018-08-08T12:35:43+0000","allowedSignatureType":{"type":"1FA","variants":["possession_knowledge"]},"formData":{"title":"Potvrzení platby","message":"Dobrý den,prosíme o potvrzení následující platby:","attributes":[{"type":"AMOUNT","id":"operation.amount","label":"Částka","amount":100,"currency":"CZK"},{"type":"KEY_VALUE","id":"operation.account","label":"Na účet","value":"238400856/0300"},{"type":"KEY_VALUE","id":"operation.dueDate","label":"Datum splatnosti","value":"29.6.2017"},{"type":"NOTE","id":"operation.note","label":"Poznámka","note":"Utility Bill Payment - 05/2017"}, {"type": "ALERT","alertType": "WARNING","id": "operation.warning","label": "Balance alert","title": "Nízký zůstatek","message": "Na účtu po platbě zůstane méně než 100 Kč."}, {"type": "ALERT","alertType": "SUCCESS","id": "operation.success","label": "Success alert","message": "Platba byla úspěšně provedena."}]}}]}
                       """
        
        guard let result = try? jsonDecoder.decode(WMTOperationListResponse<WMTUserOperation>.self, from: response.data(using: .utf8)!) else {
            Issue.record("Failed to parse JSON data")
            return
        }
        
        #expect(1676032242 == result.currentTimestamp?.timeIntervalSince1970)
        
        #expect(result.status == .ok)
        #expect(result.responseError == nil)
        
        guard let operations = result.responseObject else {
            Issue.record("response object nil")
            return
        }
        
        guard operations.count == 2 else {
            Issue.record("There should be 2 operations")
            return
        }
        
        let op = operations[0]
        
        #expect(op.id == "930febe7-f350-419a-8bc0-c8883e7f71e3")
        #expect(op.name == "authorize_payment")
        #expect(op.data == "A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017")
        #expect(op.operationCreated.timeIntervalSince1970 == 1533731442)
        #expect(op.operationExpires.timeIntervalSince1970 == 1533731743)
        #expect(op.allowedSignatureType.signatureType == .twoFactors)
        #expect(op.allowedSignatureType.signatureFactors.contains(.possessionBiometry) && op.allowedSignatureType.signatureFactors.contains(.possessionKnowledge))
        #expect(op.formData.title == "Potvrzení platby")
        #expect(op.formData.message == "Dobrý den,prosíme o potvrzení následující platby:")
        
        if op.formData.attributes.count == 8 {
            
            if let attr = op.formData.attributes[0] as? WMTOperationAttributeAmount {
                #expect(attr.type == .amount)
                #expect(attr.label.id == "operation.amount")
                #expect(attr.label.value == "Částka")
                #expect(attr.amount ==  NSDecimalNumber(string: "965165234082.23").decimalValue)
                #expect(attr.currency == "CZK")
                #expect(attr.valueFormatted == "965165234082.23 CZK")
            } else {
                Issue.record("amount attribute not recognized")
            }
            
            if let attr = op.formData.attributes[1] as? WMTOperationAttributeKeyValue {
                #expect(attr.type == .keyValue)
                #expect(attr.label.id == "operation.account")
                #expect(attr.label.value == "Na účet")
                #expect(attr.value == "238400856/0300")
            } else {
                Issue.record("account attribute not recognized")
            }
            
            if let attr = op.formData.attributes[3] as? WMTOperationAttributeNote {
                #expect(attr.type == .note)
                #expect(attr.label.id == "operation.note")
                #expect(attr.label.value == "Poznámka")
                #expect(attr.note == "Utility Bill Payment - 05/2017")
            } else {
                Issue.record("note attribute not recognized")
            }
            
            if let attr = op.formData.attributes[4] as? WMTOperationAttributePartyInfo {
                #expect(attr.type == .partyInfo)
                #expect(attr.label.id == "operation.partyInfo")
                #expect(attr.label.value == "Application")
                #expect(attr.partyInfo.websiteUrl != nil)
            } else {
                Issue.record("partyInfo attribute not recognized")
            }
            
            if let attr = op.formData.attributes[5] as? WMTOperationAttributeAmountConversion {
                #expect(attr.type == .amountConversion)
                #expect(attr.label.id == "operation.conversion")
                #expect(attr.label.value == "Conversion")
                #expect(attr.dynamic)
                #expect(attr.source.amount == 1.26)
                #expect(attr.source.currency == "ETC")
                #expect(attr.source.amountFormatted == "1.26")
                #expect(attr.source.currencyFormatted == "ETC")
                #expect(attr.source.valueFormatted == "1.26 ETC")
                #expect(attr.target.amount == 1710.98)
                #expect(attr.target.currency == "USD")
                #expect(attr.target.amountFormatted == "1,710.98")
                #expect(attr.target.currencyFormatted == "USD")
                #expect(attr.target.valueFormatted == "1,710.98 USD")
            } else {
                Issue.record("conversion attribute not recognized")
            }
            
            if let attr = op.formData.attributes[6] as? WMTOperationAttributeImage {
                #expect(attr.type == .image)
                #expect(attr.label.id == "operation.image")
                #expect(attr.label.value == "Image")
                #expect(attr.thumbnailUrl == "https://example.com/123_thumb.jpeg")
                #expect(attr.originalUrl == "https://example.com/123.jpeg")
            } else {
                Issue.record("image attribute not recognized")
            }
            
            if let attr = op.formData.attributes[7] as? WMTOperationAttributeImage {
                #expect(attr.type == .image)
                #expect(attr.label.id == "operation.image")
                #expect(attr.label.value == "Image")
                #expect(attr.thumbnailUrl == "https://example.com/123_thumb.jpeg")
                #expect(attr.originalUrl == nil)
            } else {
                Issue.record("image attribute not recognized")
            }
            
            
        } else {
            Issue.record("operation should contain 5 attributes, but contains \(op.formData.attributes.count)")
        }
        
        let op2 = operations[1]
        
        // Additional tests for the second operation (op2)
        #expect(op2.id == "930febe7-f350-419a-8bc0-c8883e7f71e3")
        #expect(op2.name == "authorize_payment")
        #expect(op2.data == "A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017")
        #expect(op2.status == .pending)
        #expect(op2.operationCreated.timeIntervalSince1970 == 1533731442)
        #expect(op2.operationExpires.timeIntervalSince1970 == 1533731743)
        #expect(op2.allowedSignatureType.signatureType == .singleFactor)
        #expect(op2.allowedSignatureType.signatureFactors == [.possessionKnowledge])
        #expect(op2.formData.title == "Potvrzení platby")
        #expect(op2.formData.message == "Dobrý den,prosíme o potvrzení následující platby:")
        
        // Test all fields in formData.attributes for op2
        if op2.formData.attributes.count == 6 {
            if let amountAttr = op2.formData.attributes[0] as? WMTOperationAttributeAmount {
                #expect(amountAttr.type == .amount)
                #expect(amountAttr.label.id == "operation.amount")
                #expect(amountAttr.label.value == "Částka")
                #expect(amountAttr.amount == NSDecimalNumber(string: "100").decimalValue)
                #expect(amountAttr.currency == "CZK")
            } else {
                Issue.record("amount attribute not recognized in op2")
            }
            if let accountAttr = op2.formData.attributes[1] as? WMTOperationAttributeKeyValue {
                #expect(accountAttr.type == .keyValue)
                #expect(accountAttr.label.id == "operation.account")
                #expect(accountAttr.label.value == "Na účet")
                #expect(accountAttr.value == "238400856/0300")
            } else {
                Issue.record("account attribute not recognized in op2")
            }
            if let dueDateAttr = op2.formData.attributes[2] as? WMTOperationAttributeKeyValue {
                #expect(dueDateAttr.type == .keyValue)
                #expect(dueDateAttr.label.id == "operation.dueDate")
                #expect(dueDateAttr.label.value == "Datum splatnosti")
                #expect(dueDateAttr.value == "29.6.2017")
            } else {
                Issue.record("dueDate attribute not recognized in op2")
            }
            if let noteAttr = op2.formData.attributes[3] as? WMTOperationAttributeNote {
                #expect(noteAttr.type == .note)
                #expect(noteAttr.label.id == "operation.note")
                #expect(noteAttr.label.value == "Poznámka")
                #expect(noteAttr.note == "Utility Bill Payment - 05/2017")
            } else {
                Issue.record("note attribute not recognized in op2")
            }

            if let alertAttr = op2.formData.attributes[4] as? WMTOperationAttributeAlert {
                #expect(alertAttr.type == .alert)
                #expect(alertAttr.label.id == "operation.warning")
                #expect(alertAttr.alertType == WMTOperationAttributeAlert.AlertType.warning)
                #expect(alertAttr.label.value == "Balance alert")
                #expect(alertAttr.title == "Nízký zůstatek")
                #expect(alertAttr.message == "Na účtu po platbě zůstane méně než 100 Kč.")
            } else {
                Issue.record("alert attribute not recognized in op2")
            }
            
            if let alert2Attr = op2.formData.attributes[5] as? WMTOperationAttributeAlert {
                #expect(alert2Attr.type == .alert)
                #expect(alert2Attr.label.id == "operation.success")
                #expect(alert2Attr.alertType == WMTOperationAttributeAlert.AlertType.success)
                #expect(alert2Attr.label.value == "Success alert")
                #expect(alert2Attr.title == nil)
                #expect(alert2Attr.message == "Platba byla úspěšně provedena.")
            } else {
                Issue.record("alert2 attribute not recognized in op2")
            }
            
        } else {
            Issue.record("op2 should contain 6 attributes, but contains \(op2.formData.attributes.count)")
        }
    }
    
    @Test
    func testOnlyAmountAndConversionAttributesLegacyBackend() {
        let json = """
        {"status":"OK", "currentTimestamp":"2023-02-10T12:30:42+0000", "responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3", "name":"authorize_payment", "status":"PENDING", "data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "operationCreated":"2018-08-08T12:30:42+0000", "operationExpires":"2018-08-08T12:35:43+0000", "allowedSignatureType": {"type":"2FA", "variants": ["possession_knowledge", "possession_biometry"]}, "formData": {"title":"Potvrzení platby", "message":"Dobrý den,prosíme o potvrzení následující platby:", "attributes": [{"type":"AMOUNT", "id":"operation.amount", "label":"Částka", "amount":965165234082.23, "currency":"CZK"}, { "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmount": 1.26, "sourceCurrency": "ETC", "targetAmount": 1710.98, "targetCurrency": "USD"}]}}]}
        """
        
        guard let result = try? jsonDecoder.decode(WPNResponseArray<WMTUserOperation>.self, from: json.data(using: .utf8)!) else {
            Issue.record("Failed to parse JSON data")
            return
        }
        
        guard let amountAttr = result.responseObject?[0].formData.attributes[0] as? WMTOperationAttributeAmount  else {
            Issue.record("amount attribute not recognized")
            return
        }
        #expect(Decimal(string: "965165234082.23") == amountAttr.amount)
        #expect("CZK" == amountAttr.currency)
        #expect("965165234082.23" == amountAttr.amountFormatted)
        #expect("CZK" == amountAttr.currencyFormatted)
        
        
        guard let conversionAttr = result.responseObject?[0].formData.attributes[1] as? WMTOperationAttributeAmountConversion else {
            Issue.record("conversion attribute not recognized")
            return
        }
    
        #expect(Decimal(string: "1.26") == conversionAttr.source.amount)
        #expect("ETC" == conversionAttr.source.currency)
        #expect(Decimal(string: "1710.98") == conversionAttr.target.amount)
        #expect("USD" == conversionAttr.target.currency)
        
        #expect("1.26" == conversionAttr.source.amountFormatted)
        #expect("ETC" == conversionAttr.source.currencyFormatted)
        #expect("1710.98" == conversionAttr.target.amountFormatted)
        #expect("USD" == conversionAttr.target.currencyFormatted)
    }

    @Test
    func testAmountAndConversionAttributesOnlyFormattedValues() {
        let json = """
        {"status":"OK", "currentTimestamp":"2023-02-10T12:30:42+0000", "responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3", "name":"authorize_payment", "status":"PENDING", "data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "operationCreated":"2018-08-08T12:30:42+0000", "operationExpires":"2018-08-08T12:35:43+0000", "allowedSignatureType": {"type":"2FA", "variants": ["possession_knowledge", "possession_biometry"]}, "formData": {"title":"Potvrzení platby", "message":"Dobrý den,prosíme o potvrzení následující platby:", "attributes": [{"type":"AMOUNT", "id":"operation.amount", "label":"Částka", "amountFormatted":"965165234082.23", "currencyFormatted":"CZK"}, { "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmountFormatted": "1.26", "sourceCurrencyFormatted": "ETC", "targetAmountFormatted": "1710.98", "targetCurrencyFormatted": "USD"}]}}]}
        """.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let result = try? jsonDecoder.decode(WPNResponseArray<WMTUserOperation>.self, from: json.data(using: .utf8)!) else {
            Issue.record("Failed to parse JSON data")
            return
        }

        guard let amountAttr = result.responseObject?[0].formData.attributes[0] as? WMTOperationAttributeAmount else {
            Issue.record("amount attribute not recognized")
            return
        }

        #expect(amountAttr.amount == nil)
        #expect(amountAttr.currency == nil)
        #expect("965165234082.23" == amountAttr.amountFormatted)
        #expect("CZK" == amountAttr.currencyFormatted)

        guard let conversionAttr = result.responseObject?[0].formData.attributes[1] as? WMTOperationAttributeAmountConversion else {
            Issue.record("conversion attribute not recognized")
            return
        }

        #expect(conversionAttr.source.amount == nil)
        #expect(conversionAttr.source.currency == nil)
        #expect(conversionAttr.target.amount == nil)
        #expect(conversionAttr.target.currency == nil)

        #expect("1.26" == conversionAttr.source.amountFormatted)
        #expect("ETC" == conversionAttr.source.currencyFormatted)
        #expect("1710.98" == conversionAttr.target.amountFormatted)
        #expect("USD" == conversionAttr.target.currencyFormatted)
    }
    
    @Test
    func testErrorResponse() {
        
        let response = """
                       {"status":"ERROR","responseObject":{"code":"INVALID_ACTIVATION","message":"Invalid activation found in Mobile Token API component."}}
                       """
        
        guard let result = try? jsonDecoder.decode(WPNResponseArray<WMTUserOperation>.self, from: response.data(using: .utf8)!) else {
            Issue.record("Failed to parse JSON data")
            return
        }
        
        #expect(result.status == .error)
        #expect(result.responseObject == nil)
        
        guard let error = result.responseError else {
            Issue.record("response error nil")
            return
        }
        
        #expect(error.errorCode == .invalidActivation)
        #expect(error.message == "Invalid activation found in Mobile Token API component.")
    }
    
    @Test
    func testUnknownAttribute() {
        let response = """
                       {"status":"OK","responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3","name":"authorize_payment","data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017","operationCreated":"2018-08-08T12:30:42+0000","status":"PENDING" ,"operationExpires":"2018-08-08T12:35:43+0000","allowedSignatureType":{"type":"2FA","variants":["possession_knowledge", "possession_biometry"]},"formData":{"title":"Potvrzení platby","message":"Dobrý den,prosíme o potvrzení následující platby:","attributes":[{"type":"THIS_IS_FAKE_ATTR","id":"operation.amount","label":"Částka","amount":965165234082.23,"currency":"CZK"},{"type":"KEY_VALUE","id":"operation.account","label":"Na účet","value":"238400856/0300"}]}}]}
                       """
        
        guard let result = try? jsonDecoder.decode(WPNResponseArray<WMTUserOperation>.self, from: response.data(using: .utf8)!) else {
            Issue.record("Failed to parse JSON data")
            return
        }
        
        #expect(result.status == .ok)
        #expect(result.responseError == nil)
        
        guard let operations = result.responseObject else {
            Issue.record("response object nil")
            return
        }
        
        guard operations.count == 1 else {
            Issue.record("There should be 1 operation")
            return
        }
        
        guard operations[0].formData.attributes.count == 2 else {
            Issue.record("There should be 2 attributes")
            return
        }
        
        #expect(operations[0].formData.attributes[0].type == .unknown, "Attribute should be unknown")
    }
    
    @Test
    func testOperationAuthorizationRequest() {
        
        let expectation = """
                          {"requestObject":{"id":"95e51995-fa60-4018-bd87-43a58f098570","data":"RANDOMDATA"}}
                          """
        let request = WMTOperationEndpoints.Authorize.EndpointType.RequestData(.init(operationId: "95e51995-fa60-4018-bd87-43a58f098570", operationData: "RANDOMDATA"))

        request.testSerialization(expectation: expectation)
    }
    
    @Test
    func testTOTPOperationAuthorizationRequest() {

        let response = """
                    {"status":"OK","responseObject":[{"id":"47825519-35b8-469d-ad76-e42f85b9a31d","name":"login_preApproval","data":"A2","status":"PENDING","operationCreated":"2023-10-27T11:04:00+0000","operationExpires":"2023-10-27T11:54:00+0000","ui":{"preApprovalScreen":{"type":"QR_SCAN","heading":"Scan the QR code!","message":"To verify that you are close by, please scan the code from the monitor."}},"allowedSignatureType":{"type":"2FA","variants":["possession_knowledge","possession_biometry"]},"formData":{"title":"Login Approval","message":"Are you logging in to the internet banking?","attributes":[]}}],"currentTimestamp":"2023-10-27T11:04:15+0000"}
                    """
        guard let result = try? jsonDecoder.decode(WMTOperationListResponse<WMTUserOperation>.self, from: response.data(using: .utf8)!) else {
            Issue.record("Failed to parse JSON data")
            return
        }
        
        guard let operations = result.responseObject else {
            Issue.record("response object nil")
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
        
        #expect(request.requestObject?.data == "A2")
        #expect(request.requestObject?.id == "47825519-35b8-469d-ad76-e42f85b9a31d")
        #expect(proximityCheck?.type == .qrCode)
        #expect(proximityCheck?.otp == "12345678")
    }
    
    @Test
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
        
        #expect(request.requestObject?.data == "test-operation-data")
        #expect(request.requestObject?.id == "test-operation-id")
        #expect(request.requestObject?.mobileTokenData != nil)
        
        // Verify mobile token data content
        if let data = request.requestObject?.mobileTokenData {
            if let deviceFingerprint = data["deviceFingerprint"]?.original as? String {
                #expect(deviceFingerprint == "abc123")
            } else {
                Issue.record("Device fingerprint should be a string")
            }
            
            if let riskScore = data["riskScore"]?.original as? Double {
                #expect(abs(riskScore - 0.8) <= 0.001)
            } else {
                Issue.record("Risk score should be a double")
            }
            
            if let location = data["location"]?.original as? [String: Double] {
                if let lat = location["latitude"] {
                    #expect(abs(lat - 50.0755) <= 0.0001)
                } else {
                    Issue.record("Latitude should be present")
                }
                if let lon = location["longitude"] {
                    #expect(abs(lon - 14.4378) <= 0.0001)
                } else {
                    Issue.record("Longitude should be present")
                }
            } else {
                Issue.record("Location should be a dictionary")
            }
        } else {
            Issue.record("Mobile token data should be present")
        }
        
        // Test operation without mobile token data (backward compatibility)
        let simpleOp = WMTLocalOperation(id: "simple-id", data: "simple-data")
        let simpleRequest = WMTOperationEndpoints.Authorize.EndpointType.RequestData(.init(operation: simpleOp))
        
        #expect(simpleRequest.requestObject?.data == "simple-data")
        #expect(simpleRequest.requestObject?.id == "simple-id")
        #expect(simpleRequest.requestObject?.mobileTokenData == nil)
    }
    
    @Test
    func testOperationRejectionRequest() {
        
        let expectation = """
                          {"requestObject":{"id":"95e51995-fa60-4018-bd87-43a58f098570","reason":"COMPLETELLY_CUSTOM_REJECT_REASON"}}
                          """
        
        let request = WMTOperationEndpoints.Reject.EndpointType.RequestData(.init(operationId: "95e51995-fa60-4018-bd87-43a58f098570", reason: .custom("COMPLETELLY_CUSTOM_REJECT_REASON")))
        request.testSerialization(expectation: expectation)
    }
    
    @Test
    func testHistoryResponse() {
        let response = """
{ "status":"OK", "responseObject":[ { "id":"0775afb2-4f06-4ed9-b990-a35bab4cac3b", "name":"login-tpp", "data":"A2*R666*R123", "status":"PENDING", "operationCreated":"2021-08-09T15:32:24+0000", "operationExpires":"2021-08-09T15:37:24+0000", "allowedSignatureType":{ "type":"2FA", "variants":[ "possession_knowledge", "possession_biometry" ] }, "formData":{ "title":"Login Approval", "message":"Are you logging in to the third party application?", "attributes":[ { "type":"KEY_VALUE", "id":"party.name", "label":"Third Party App", "value":"Datová schránka" }, { "type":"KEY_VALUE", "id":"party.id", "label":"Application ID", "value":"666" }, { "type":"KEY_VALUE", "id":"session.id", "label":"Session ID", "value":"123" }, { "type":"KEY_VALUE", "id":"session.ip-address", "label":"IP Address", "value":"192.168.0.1" } ] } }, { "id":"5bbe1d48-d2f0-43fb-8612-75917a9761fb", "name":"login-tpp", "data":"A2*R666*R123", "status":"REJECTED", "operationCreated":"2021-08-09T15:32:15+0000", "operationExpires":"2021-08-09T15:37:15+0000", "allowedSignatureType":{ "type":"2FA", "variants":[ "possession_knowledge", "possession_biometry" ] }, "formData":{ "title":"Login Approval", "message":"Are you logging in to the third party application?", "attributes":[ { "type":"KEY_VALUE", "id":"party.name", "label":"Third Party App", "value":"Datová schránka" }, { "type":"KEY_VALUE", "id":"party.id", "label":"Application ID", "value":"666" }, { "type":"KEY_VALUE", "id":"session.id", "label":"Session ID", "value":"123" }, { "type":"KEY_VALUE", "id":"session.ip-address", "label":"IP Address", "value":"192.168.0.1" } ] } }, { "id":"8bbff7b6-03c4-470c-9320-4660c3bf1f01", "name":"login-tpp", "data":"A2*R666*R123", "status":"APPROVED", "operationCreated":"2021-08-09T15:31:55+0000", "operationExpires":"2021-08-09T15:36:55+0000", "allowedSignatureType":{ "type":"2FA", "variants":[ "possession_knowledge", "possession_biometry" ] }, "formData":{ "title":"Login Approval", "message":"Are you logging in to the third party application?", "attributes":[ { "type":"KEY_VALUE", "id":"party.name", "label":"Third Party App", "value":"Datová schránka" }, { "type":"KEY_VALUE", "id":"party.id", "label":"Application ID", "value":"666" }, { "type":"KEY_VALUE", "id":"session.id", "label":"Session ID", "value":"123" }, { "type":"KEY_VALUE", "id":"session.ip-address", "label":"IP Address", "value":"192.168.0.1" } ] } }, { "id":"8bbff7b6-03c4-470c-9320-4660c3bf1f01", "name":"login-tpp", "data":"A2*R666*R123", "status":"CANCELED", "operationCreated":"2021-08-09T15:31:55+0000", "operationExpires":"2021-08-09T15:36:55+0000", "allowedSignatureType":{ "type":"2FA", "variants":[ "possession_knowledge", "possession_biometry" ] }, "formData":{ "title":"Login Approval", "message":"Are you logging in to the third party application?", "attributes":[ { "type":"KEY_VALUE", "id":"party.name", "label":"Third Party App", "value":"Datová schránka" }, { "type":"KEY_VALUE", "id":"party.id", "label":"Application ID", "value":"666" }, { "type":"KEY_VALUE", "id":"session.id", "label":"Session ID", "value":"123" }, { "type":"KEY_VALUE", "id":"session.ip-address", "label":"IP Address", "value":"192.168.0.1" } ] } }, { "id":"8bbff7b6-03c4-470c-9320-4660c3bf1f01", "name":"login-tpp", "data":"A2*R666*R123", "status":"EXPIRED", "operationCreated":"2021-08-09T15:31:55+0000", "operationExpires":"2021-08-09T15:36:55+0000", "allowedSignatureType":{ "type":"2FA", "variants":[ "possession_knowledge", "possession_biometry" ] }, "formData":{ "title":"Login Approval", "message":"Are you logging in to the third party application?", "attributes":[ { "type":"KEY_VALUE", "id":"party.name", "label":"Third Party App", "value":"Datová schránka" }, { "type":"KEY_VALUE", "id":"party.id", "label":"Application ID", "value":"666" }, { "type":"KEY_VALUE", "id":"session.id", "label":"Session ID", "value":"123" }, { "type":"KEY_VALUE", "id":"session.ip-address", "label":"IP Address", "value":"192.168.0.1" } ] } }, { "id":"8bbff7b6-03c4-470c-9320-4660c3bf1f01", "name":"login-tpp", "data":"A2*R666*R123", "status":"FAILED", "operationCreated":"2021-08-09T15:31:55+0000", "operationExpires":"2021-08-09T15:36:55+0000", "allowedSignatureType":{ "type":"2FA", "variants":[ "possession_knowledge", "possession_biometry" ] }, "formData":{ "title":"Login Approval", "message":"Are you logging in to the third party application?", "attributes":[ { "type":"KEY_VALUE", "id":"party.name", "label":"Third Party App", "value":"Datová schránka" }, { "type":"KEY_VALUE", "id":"party.id", "label":"Application ID", "value":"666" }, { "type":"KEY_VALUE", "id":"session.id", "label":"Session ID", "value":"123" }, { "type":"KEY_VALUE", "id":"session.ip-address", "label":"IP Address", "value":"192.168.0.1" } ] } } ] }
"""
        
        guard let result = try? jsonDecoder.decode(WPNResponseArray<WMTUserOperation>.self, from: response.data(using: .utf8)!) else {
            Issue.record("Failed to parse JSON data")
            return
        }
        
        #expect(result.status == .ok)
        #expect(result.responseObject != nil)
        
        guard let obj = result.responseObject else {
            Issue.record("response object nil")
            return
        }
        
        // each enum case should be inside the JSON
        WMTUserOperation.Status.allCases.forEach { val in
            #expect(obj.filter({ $0.status == val }).count == 1)
        }
    }
    
    @Test
    func testAttributesDeserializationNotInterupted() {
        // Non-optional amount removed from AMOUNT Attribute
        let response = """
{"status":"OK", "currentTimestamp":"2023-02-10T12:30:42+0000", "responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3", "name":"authorize_payment", "data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "status":"PENDING", "operationCreated":"2018-08-08T12:30:42+0000", "operationExpires":"2018-08-08T12:35:43+0000", "allowedSignatureType": {"type":"2FA", "variants": ["possession_knowledge", "possession_biometry"]}, "formData": {"title":"Potvrzení platby", "message":"Dobrý den,prosíme o potvrzení následující platby:", "attributes": [{"type":"AMOUNT", "id":"operation.amount", "label":"Částka", "currency":"CZK"}, { "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmount": 1.26, "sourceCurrency": "ETC", "targetAmount": 1710.98, "targetCurrency": "USD"}]}}]}
"""

        guard let result = try? jsonDecoder.decode(WPNResponseArray<WMTUserOperation>.self, from: response.data(using: .utf8)!) else {
            Issue.record("Failed to parse JSON data")
            return
        }
        
        guard let attributes = result.responseObject?[0].formData.attributes else {
            Issue.record("Failed to get attributes")
            return
        }
        
        #expect(attributes.count == 1, "There should be one Conversion Attribute but the count is: \(attributes.count)")
        #expect(attributes.first is WMTOperationAttributeAmountConversion)
    }
    
    @Test
    func testResultTexts() {
        let response = """
{"status":"OK", "currentTimestamp":"2023-02-10T12:30:42+0000", "responseObject":[{"id":"930febe7-f350-419a-8bc0-c8883e7f71e3", "name":"authorize_payment", "data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "status": "PENDING", "operationCreated":"2018-08-08T12:30:42+0000", "operationExpires":"2018-08-08T12:35:43+0000", "allowedSignatureType": {"type":"2FA", "variants": ["possession_knowledge", "possession_biometry"]}, "formData": {"title":"Potvrzení platby", "message":"Dobrý den,prosíme o potvrzení následující platby:", "attributes": [{"type":"AMOUNT", "id":"operation.amount", "label":"Částka", "currency":"CZK"}, { "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmount": 1.26, "sourceCurrency": "ETC", "targetAmount": 1710.98, "targetCurrency": "USD"}]}}, {"id":"930febe7-f350-419a-8bc0-c8883e7f71e3", "name":"authorize_payment", "data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "status": "PENDING", "operationCreated":"2018-08-08T12:30:42+0000", "operationExpires":"2018-08-08T12:35:43+0000", "allowedSignatureType": {"type":"2FA", "variants": ["possession_knowledge", "possession_biometry"]}, "formData": {"title":"Potvrzení platby", "message":"Dobrý den,prosíme o potvrzení následující platby:", "resultTexts": {"success": "Payment of was confirmed"}, "attributes": [{"type":"AMOUNT", "id":"operation.amount", "label":"Částka", "currency":"CZK"}, { "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmount": 1.26, "sourceCurrency": "ETC", "targetAmount": 1710.98, "targetCurrency": "USD"}]}}, {"id":"930febe7-f350-419a-8bc0-c8883e7f71e3", "name":"authorize_payment", "data":"A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017", "status": "PENDING", "operationCreated":"2018-08-08T12:30:42+0000", "operationExpires":"2018-08-08T12:35:43+0000", "allowedSignatureType": {"type":"2FA", "variants": ["possession_knowledge", "possession_biometry"]}, "formData": {"title":"Potvrzení platby", "message":"Dobrý den,prosíme o potvrzení následující platby:", "resultTexts": {"success": "Payment of was confirmed", "reject": "Payment was rejected", "failure": "Payment approval failed"},"attributes": [{"type":"AMOUNT", "id":"operation.amount", "label":"Částka", "currency":"CZK"}, { "type": "AMOUNT_CONVERSION", "id": "operation.conversion", "label": "Conversion", "dynamic": true, "sourceAmount": 1.26, "sourceCurrency": "ETC", "targetAmount": 1710.98, "targetCurrency": "USD"}]}}]}
"""
        
        guard let result = try? jsonDecoder.decode(WPNResponseArray<WMTUserOperation>.self, from: response.data(using: .utf8)!) else {
            Issue.record("Failed to parse JSON data")
            return
        }
        
        #expect(result.responseObject?[0].formData.resultTexts == nil)
        
        guard let resultTexts1 = result.responseObject?[1].formData.resultTexts else {
            Issue.record("Failed to get resultTexts1")
            return
        }
        
        #expect(resultTexts1.success == "Payment of was confirmed")
        #expect(resultTexts1.reject == nil)
        #expect(resultTexts1.failure == nil)
        
        guard let resultTexts2 = result.responseObject?[2].formData.resultTexts else {
            Issue.record("Failed to get resultTexts2")
            return
        }
        
        let createdTexts = WMTResultTexts(success: "Payment of was confirmed", failure: "Payment approval failed", reject: "Payment was rejected")
        
        #expect(resultTexts2.success == createdTexts.success)
        #expect(resultTexts2.reject == createdTexts.reject)
        #expect(resultTexts2.failure == createdTexts.failure)
    }
    
    @Test
    func testOperationWithStatus() {
        let response = """
            {"responseObject":[{"id":"e10bbc25-cf42-4812-815e-3972f49d8f7f","name":"login","data":"A2","status":"CANCELED","operationCreated":"2025-07-29T14:43:33+0000","operationExpires":"2025-07-29T14:48:33+0000","allowedSignatureType":{"type":"2FA","variants":["possession_knowledge","possession_biometry"]},"formData":{"title":"Login Approval","message":"Are you logging in to the internet banking?","attributes":[]}}],"status":"OK","currentTimestamp":"2025-07-29T14:43:36+0000"}
            """
        
        guard let result = try? jsonDecoder.decode(WPNResponseArray<WMTUserOperation>.self, from: response.data(using: .utf8)!).responseObject?[0] else {
            Issue.record("Failed to parse JSON data")
            return
        }
        
        #expect(result.status == .canceled)
    }
    
    @Test
    func testOperationWithoutStatus() {
        let response = """
            {"responseObject":[{"id":"e10bbc25-cf42-4812-815e-3972f49d8f7f","name":"login","data":"A2","operationCreated":"2025-07-29T14:43:33+0000","operationExpires":"2025-07-29T14:48:33+0000","allowedSignatureType":{"type":"2FA","variants":["possession_knowledge","possession_biometry"]},"formData":{"title":"Login Approval","message":"Are you logging in to the internet banking?","attributes":[]}}],"status":"OK","currentTimestamp":"2025-07-29T14:43:36+0000"}
            """
        
        guard let result = try? jsonDecoder.decode(WPNResponseArray<WMTUserOperation>.self, from: response.data(using: .utf8)!).responseObject?[0] else {
            Issue.record("Failed to parse JSON data")
            return
        }
        
        // when status is missing, defaults to "PENDING"
        #expect(result.status == .pending)
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
            Issue.record("Failed to encode request data")
            return
        }

        // Convert String to Data
        guard let expectationData = expectation.data(using: .utf8) else {
            Issue.record("Failed to encode expectation string")
            return
        }
        
        // Convert to [String: Any]
        guard let expectationDict = try? JSONSerialization.jsonObject(with: expectationData) as? [String: Any],
               let jsonDataDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            Issue.record("Failed to cast data to format [String: Any]")
            return
        }
        
        // Convert back to data with sorted keys
        guard let sortedExpectationData = try? JSONSerialization.data(withJSONObject: expectationDict, options: [.sortedKeys]),
                let sortedJsonData = try? JSONSerialization.data(withJSONObject: jsonDataDict, options: [.sortedKeys]) else {
            Issue.record("Failed to sort data")
            return
        }
                
        // Convert Data back to strings for comparison
        guard let sortedExpectationString = String(data: sortedExpectationData, encoding: .utf8),
              let sortedJsonDataString = String(data: sortedJsonData, encoding: .utf8) else {
            Issue.record("Failed to cast data to string")
            return
        }
                    
        #expect(sortedExpectationString == sortedJsonDataString, "Serialized Strings doesn't match")
    }
}
