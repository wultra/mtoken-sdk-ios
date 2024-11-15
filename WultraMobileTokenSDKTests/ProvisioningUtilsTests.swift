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
@testable import WultraMobileTokenSDK

class ProvisioningUtilsTests: XCTestCase {
    
    func testParseDevelopmentAPNS() {
        let profile = getProfile("development")
        let dict = WMTProvisioningUtils.parseProvisioningProfile(profile.data(using: .utf8)!)
        let env = WMTProvisioningUtils.getApnsEnvironment(profileDict: dict)
        XCTAssertEqual(env, .development)
    }
    
    func testParseProductionAPNS() {
        let profile = getProfile("production")
        let dict = WMTProvisioningUtils.parseProvisioningProfile(profile.data(using: .utf8)!)
        let env = WMTProvisioningUtils.getApnsEnvironment(profileDict: dict)
        XCTAssertEqual(env, .production)
    }
    
    func testParseMissingAPNS() {
        let profile = getProfile(nil)
        let dict = WMTProvisioningUtils.parseProvisioningProfile(profile.data(using: .utf8)!)
        let env = WMTProvisioningUtils.getApnsEnvironment(profileDict: dict)
        XCTAssertEqual(env, nil)
    }
    
    func testParseUnknownAPNS() {
        let profile = getProfile("integration") // unknown value
        let dict = WMTProvisioningUtils.parseProvisioningProfile(profile.data(using: .utf8)!)
        let env = WMTProvisioningUtils.getApnsEnvironment(profileDict: dict)
        XCTAssertEqual(env, nil)
    }
    
    private func getProfile(_ apnsEnvironment: String?) -> String {
        let entry = apnsEnvironment != nil ? "<key>aps-environment</key><string>\(apnsEnvironment!)</string>": ""
        return """
                <?xml version="1.0" encoding="UTF-8"?>
                <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
                <plist version="1.0">
                <dict>
                    \(entry)
                </dict>
                </plist>
               """
    }
}
