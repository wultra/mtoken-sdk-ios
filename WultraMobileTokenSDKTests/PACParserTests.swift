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
import WultraMobileTokenSDK

final class PACParserTest: XCTestCase {

    func testQRPACParserWithEmptyCode() {
        let code = ""
        
        XCTAssertNil(WMTPACUtils.parseQRCode(code: code))
    }
    
    func testQRPACParserWithShortInvalidCode() {
        let code = "abc"
        
        XCTAssertNil(WMTPACUtils.parseQRCode(code: code))
    }
    
    func testQRTPACParserWithValidDeeplinkCode() {
        let code = "scheme://operation?oid=6a1cb007-ff75-4f40-a21b-0b546f0f6cad&potp=73743194"
        
        XCTAssertEqual(WMTPACUtils.parseQRCode(code: code)?.totp, "73743194", "Parsing of totp failed")
        XCTAssertEqual(WMTPACUtils.parseQRCode(code: code)?.operationId, "6a1cb007-ff75-4f40-a21b-0b546f0f6cad", "Parsing of operationId failed")
    }
    
    func testQRTPACParserWithValidDeeplinkCodeAndBase64OID() {
        let code = "scheme://operation?oid=E/+DRFVmd4iZABEiM0RVZneImQARIjNEVWZ3iJkAESIzRFVmd4iZAA=&totp=12345678"
        
        XCTAssertEqual(WMTPACUtils.parseQRCode(code: code)?.totp, "12345678", "Parsing of totp failed")
        XCTAssertEqual(WMTPACUtils.parseQRCode(code: code)?.operationId, "E/+DRFVmd4iZABEiM0RVZneImQARIjNEVWZ3iJkAESIzRFVmd4iZAA=", "Parsing of operationId failed")
    }
    
    func testQRTPACParserWithValidDeeplinkCodeAndBase64EncodedOID() {
        let code = "scheme://operation?oid=E%2F%2BDRFVmd4iZABEiM0RVZneImQARIjNEVWZ3iJkAESIzRFVmd4iZAA%3D&totp=12345678"
        
        XCTAssertEqual(WMTPACUtils.parseQRCode(code: code)?.totp, "12345678", "Parsing of totp failed")
        XCTAssertEqual(WMTPACUtils.parseQRCode(code: code)?.operationId, "E/+DRFVmd4iZABEiM0RVZneImQARIjNEVWZ3iJkAESIzRFVmd4iZAA=", "Parsing of operationId failed")
    }

    func testQRPACParserWithValidJWT() {
        let code = "eyJhbGciOiJub25lIiwidHlwZSI6IkpXVCJ9.eyJvaWQiOiIzYjllZGZkMi00ZDgyLTQ3N2MtYjRiMy0yMGZhNWM5OWM5OTMiLCJwb3RwIjoiMTQzNTc0NTgifQ=="
        let parsed = WMTPACUtils.parseQRCode(code: code)
        XCTAssertEqual(parsed?.totp, "14357458", "Parsing of totp failed")
        XCTAssertEqual(WMTPACUtils.parseQRCode(code: code)?.operationId, "3b9edfd2-4d82-477c-b4b3-20fa5c99c993", "Parsing of operationId failed")
    }
    
    func testQRPACParserWithValidJWTWithoutPadding() {
        let code = "eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIn0.eyJvaWQiOiJMRG5JY0NjRGhjRHdHNVNLejhLeWdQeG9PbXh3dHpJc29zMEUrSFBYUHlvIiwicG90cCI6IjU4NTkwMDU5In0"
        let parsed = WMTPACUtils.parseQRCode(code: code)
        XCTAssertEqual(parsed?.totp, "58590059", "Parsing of totp failed")
        XCTAssertEqual(parsed?.operationId, "LDnIcCcDhcDwG5SKz8KygPxoOmxwtzIsos0E+HPXPyo", "Parsing of operationId failed")
    }
    
    func testQRPACParserWithInvalidJWT() {
        let code = "eyJhbGciOiJub25lIiwidHlwZSI6IkpXVCJ9eyJvaWQiOiIzYjllZGZkMi00ZDgyLTQ3N2MtYjRiMy0yMGZhNWM5OWM5OTMiLCJwb3RwIjoiMTQzNTc0NTgifQ=="
        let parsed = WMTPACUtils.parseQRCode(code: code)
        XCTAssertNil(parsed, "Parsing of should fail")
    }
    
    func testQRPACParserWithInvalidJWT2() {
        let code = "eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIn0.1eyJvaWQiOiJMRG5JY0NjRGhjRHdHNVNLejhLeWdQeG9PbXh3dHpJc29zMEUrSFBYUHlvIiwicG90cCI6IjU4NTkwMDU5In0"
        let parsed = WMTPACUtils.parseQRCode(code: code)
        XCTAssertNil(parsed, "Parsing of should fail")
    }
    
    func testQRPACParserWithInvalidJWT3() {
        let code = ""
        let parsed = WMTPACUtils.parseQRCode(code: code)
        XCTAssertNil(parsed, "Parsing of should fail")
    }
    
    func testQRPACParserWithInvalidJWT4() {
        let code = "eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIn0.1eyJvaWQiOiJMRG5JY0NjR.GhjRHdHNVNLejhLeWdQeG9PbXh3dHpJc29zMEUrSFBYUHlvIiwicG90cCI6IjU4NTkwMDU5In0====="
        let parsed = WMTPACUtils.parseQRCode(code: code)
        XCTAssertNil(parsed, "Parsing of should fail")
    }
    
    func testDeeplinkParserWithInvalidPACCode() {
        let code = "operation?oid=df6128fc-ca51-44b7-befa-ca0e1408aa63&potp=56725494"
        
        XCTAssertNil(WMTPACUtils.parseQRCode(code: code))
    }
    
    func testDeeplinkPACParserWithInvalidURL() {
        let url = URL(string: "scheme://an-invalid-url.com")!
        XCTAssertNil(WMTPACUtils.parseDeeplink(url: url))
    }
    
    func testDeeplinkParserWithValidURLButInvalidQuery() {
        let url = URL(string: "scheme://operation?code=abc")!
        
        XCTAssertNil(WMTPACUtils.parseDeeplink(url: url))
    }
    
    func testDeeplinkPACParserWithValidJWTCode() {
        let url = URL(string: "scheme://operation?code=eyJhbGciOiJub25lIiwidHlwZSI6IkpXVCJ9.eyJvaWQiOiIzYjllZGZkMi00ZDgyLTQ3N2MtYjRiMy0yMGZhNWM5OWM5OTMiLCJwb3RwIjoiMTQzNTc0NTgifQ==")!
        
        XCTAssertEqual(WMTPACUtils.parseDeeplink(url: url)?.totp, "14357458", "Parsing of totp failed")
        XCTAssertEqual(WMTPACUtils.parseDeeplink(url: url)?.operationId, "3b9edfd2-4d82-477c-b4b3-20fa5c99c993", "Parsing of operationId failed")
    }

    func testDeeplinkParserWithValidPACCode() {
        let url = URL(string: "scheme://operation?oid=df6128fc-ca51-44b7-befa-ca0e1408aa63&potp=56725494")!
        
        XCTAssertEqual(WMTPACUtils.parseDeeplink(url: url)?.totp, "56725494", "Parsing of totp failed")
        XCTAssertEqual(WMTPACUtils.parseDeeplink(url: url)?.operationId, "df6128fc-ca51-44b7-befa-ca0e1408aa63", "Parsing of operationId failed")
    }
    
    func testDeeplinkPACParserWithValidAnonymousDeeplinkQRCode() {
        let code = "scheme://operation?oid=df6128fc-ca51-44b7-befa-ca0e1408aa63"
        
        XCTAssertNil(WMTPACUtils.parseQRCode(code: code)?.totp)
        XCTAssertEqual(WMTPACUtils.parseQRCode(code: code)?.operationId, "df6128fc-ca51-44b7-befa-ca0e1408aa63", "Parsing of operationId failed")
    }
    
    func testDeeplinkPACParserWithAnonymousJWTQRCodeWithOnlyOperationId() {
        let code = "eyJhbGciOiJub25lIiwidHlwZSI6IkpXVCJ9.eyJvaWQiOiI1YWM0YjNlOC05MjZmLTQ1ZjAtYWUyOC1kMWJjN2U2YjA0OTYifQ=="
        
        XCTAssertNil(WMTPACUtils.parseQRCode(code: code)?.totp)
        XCTAssertEqual(WMTPACUtils.parseQRCode(code: code)?.operationId, "5ac4b3e8-926f-45f0-ae28-d1bc7e6b0496", "Parsing of operationId failed")
    }
}
