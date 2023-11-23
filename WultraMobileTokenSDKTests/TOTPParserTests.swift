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
        
        XCTAssertNil(WMTPACUtils.parseQRCode(code: code))
    }
    
    func testQRTOTPParserWithShortCode() {
        let code = "abc"
        
        XCTAssertNil(WMTPACUtils.parseQRCode(code: code))
    }
    
    func testQRTOTPParserWithValidCode() {
        let code = "scheme://operation?oid=5b753d0d-d59a-49b7-bec4-eae258566dbb&totp=12345678"
        
        XCTAssertEqual(WMTPACUtils.parseQRCode(code: code)?.totp, "12345678", "Parsing of totp failed")
        XCTAssertEqual(WMTPACUtils.parseQRCode(code: code)?.operationId, "5b753d0d-d59a-49b7-bec4-eae258566dbb", "Parsing of operationId failed")
    }

    
    func testDeeplinkTOTPParserWithInvalidURL() {
        let url = URL(string: "mtoken://an-invalid-url.com")!
        XCTAssertNil(WMTPACUtils.parseDeeplink(url: url))
    }
    
    func testDeeplinkTOTPParserWithInvalidJWTCode() {
        let url = URL(string: "mtoken://login?code=abc")!
        
        XCTAssertNil(WMTPACUtils.parseDeeplink(url: url))
    }
    
    func testDeeplinkTOTPParserWithValidJWTCode() {
        let url = URL(string: "scheme://operation?oid=5b753d0d-d59a-49b7-bec4-eae258566dbb&totp=12345678")!
        
        XCTAssertEqual(WMTPACUtils.parseDeeplink(url: url)?.totp, "12345678", "Parsing of totp failed")
        XCTAssertEqual(WMTPACUtils.parseDeeplink(url: url)?.operationId, "5b753d0d-d59a-49b7-bec4-eae258566dbb", "Parsing of operationId failed")
    }
}
