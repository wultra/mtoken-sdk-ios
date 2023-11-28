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

final class TOTPParserTest: XCTestCase {

    func testQRTOTPParserWithEmptyCode() {
        let code = ""
        
        XCTAssertNil(WMTTOTPUtils.parseQRCode(code: code))
    }
    
    func testQRTOTPParserWithShortCode() {
        let code = "abc"
        
        XCTAssertNil(WMTTOTPUtils.parseQRCode(code: code))
    }
    
    func testQRTOTPParserWithValidCode() {
        let code = "eyJhbGciOiJub25lIiwidHlwZSI6IkpXVCJ9.eyJvaWQiOiI5OWZjZjc5Mi1mMjhiLTRhZGEtYmVlNy1mYjY4ZDE5ZTA1OGYiLCJwb3RwIjoiNjI2NTY0MTMifQ=="
        
        XCTAssertEqual(WMTTOTPUtils.parseQRCode(code: code)?.totp, "62656413", "Parsing of totp failed")
        XCTAssertEqual(WMTTOTPUtils.parseQRCode(code: code)?.operationId, "99fcf792-f28b-4ada-bee7-fb68d19e058f", "Parsing of operationId failed")
    }

    
    func testDeeplinkTOTPParserWithInvalidURL() {
        let url = URL(string: "mtoken://an-invalid-url.com")!
        XCTAssertNil(WMTTOTPUtils.parseDeeplink(url: url))
    }
    
    func testDeeplinkTOTPParserWithInvalidJWTCode() {
        let url = URL(string: "mtoken://login?code=abc")!
        
        XCTAssertNil(WMTTOTPUtils.parseDeeplink(url: url))
    }
    
    func testDeeplinkTOTPParserWithValidJWTCode() {
        let url = URL(string: "mtoken://login?code=eyJhbGciOiJub25lIiwidHlwZSI6IkpXVCJ9.eyJvaWQiOiI5OWZjZjc5Mi1mMjhiLTRhZGEtYmVlNy1mYjY4ZDE5ZTA1OGYiLCJwb3RwIjoiNjI2NTY0MTMifQ==")!
        
        XCTAssertEqual(WMTTOTPUtils.parseDeeplink(url: url)?.totp, "62656413", "Parsing of totp failed")
        XCTAssertEqual(WMTTOTPUtils.parseDeeplink(url: url)?.operationId, "99fcf792-f28b-4ada-bee7-fb68d19e058f", "Parsing of operationId failed")
    }
}
