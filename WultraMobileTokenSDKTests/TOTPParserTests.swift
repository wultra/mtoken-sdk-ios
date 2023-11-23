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
        let code = "eyJhbGciOiJub25lIiwidHlwZSI6IkpXVCJ9.eyJvaWQiOiI2YTFjYjAwNy1mZjc1LTRmNDAtYTIxYi0wYjU0NmYwZjZjYWQiLCJ0b3RwIjoiNzM3NDMxOTQifQ=="
        
        XCTAssertEqual(WMTPACUtils.parseQRCode(code: code)?.totp, "73743194", "Parsing of totp failed")
        XCTAssertEqual(WMTPACUtils.parseQRCode(code: code)?.operationId, "6a1cb007-ff75-4f40-a21b-0b546f0f6cad", "Parsing of operationId failed")
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
        let url = URL(string: "mtoken://login?code=eyJhbGciOiJub25lIiwidHlwZSI6IkpXVCJ9.eyJvaWQiOiJkZjYxMjhmYy1jYTUxLTQ0YjctYmVmYS1jYTBlMTQwOGFhNjMiLCJ0b3RwIjoiNTY3MjU0OTQifQ==")!
        
        XCTAssertEqual(WMTPACUtils.parseDeeplink(url: url)?.totp, "56725494", "Parsing of totp failed")
        XCTAssertEqual(WMTPACUtils.parseDeeplink(url: url)?.operationId, "df6128fc-ca51-44b7-befa-ca0e1408aa63", "Parsing of operationId failed")
    }
}
