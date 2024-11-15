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
        let plist = getProfile("development")
        let profile = WMTProvisioningUtils.parseProvisioningProfile(plist)
        let env = WMTProvisioningUtils.getApnsEnvironment(profile: profile)
        XCTAssertEqual(env, .development)
    }
    
    func testParseProductionAPNS() {
        let plist = getProfile("production")
        let profile = WMTProvisioningUtils.parseProvisioningProfile(plist)
        let env = WMTProvisioningUtils.getApnsEnvironment(profile: profile)
        XCTAssertEqual(env, .production)
    }
    
    func testParseMissingAPNS() {
        let plist = getProfile(nil)
        let profile = WMTProvisioningUtils.parseProvisioningProfile(plist)
        let env = WMTProvisioningUtils.getApnsEnvironment(profile: profile)
        XCTAssertEqual(env, nil)
    }
    
    func testParseUnknownAPNS() {
        let plist = getProfile("integration") // unknown value
        let profile = WMTProvisioningUtils.parseProvisioningProfile(plist)
        let env = WMTProvisioningUtils.getApnsEnvironment(profile: profile)
        XCTAssertEqual(env, nil)
    }
    
    private func getProfile(_ apnsEnvironment: String?) -> Data {
        let entry = if let apnsEnvironment {
            "<key>aps-environment</key><string>\(apnsEnvironment)</string>"
        } else {
            ""
        }
        return "<plist version=\"1.0\"> <dict> <key>AppIDName</key> <string>for testing purposes</string> <key>ApplicationIdentifierPrefix</key> <array> <string>ASDASDASD</string> </array> <key>CreationDate</key> <date>2024-01-08T10:59:17Z</date> <key>Platform</key> <array> <string>iOS</string> <string>xrOS</string> <string>visionOS</string> </array> <key>IsXcodeManaged</key> <true/> <key>DeveloperCertificates</key> <array> <data>pqi3u4hrjkanfkjanldfjkansd;fiohLmFwcC5Nb2JpbGVUb2tlbi5kZXYwggEIDBVEZXZlbG9wZXJDZXJ0aWZpY2F0ZXMwge4EILJ8BwOI38tdzUcaq6hIvRRO6D2QmN9HDEf7QPB+6axsBCBvpLxOYiaJykpTpjoFwyvfZclkQGG4S2Cw0HC8qrenSwQgkdZR2h310zeFWcJiJua9POg+E1qI0DXyAH5rGHXbnQsEIMr0/eY+Qqyujx1sNvG12cizX5KaudM3CjtzvsVqIKnkBCDccTpELoQR0s/FEqUpCem1yCEqtgKE8kD3kOAdggSYJQQgxcz/0oI5Y8l0uI7f5zgaT1wi3WomccHWmtoOq3HPyjIEIElhcDeOADtptU1rQvX21BVbyIKYOwwEGDa1bJ+QeATEMIIBiwwMRW50aXRsZW1lbnRzcIIBeQIBAbCCAXIwQwwWYXBwbGljYXRpb24taWRlbnRpZmllcgwpS1RUOUc4NTlNUi5jb20ud3VsdHJhLmFwcC5Nb2JpbGVUb2tlbi5kZXYwHgwPYXBzLWVudmlyb25tZW50DAtkZXZlbG9wbWVudDAxDCNjb20uYXBwbGUuZGV2ZWxvcGVyLnRlYW0taWRlbnRpZmllcgwKS1RUOUc4NTlNUjCBhwwlY29tLmFwcGxlLnNlY3VyaXR5LmFwcGxpY2F0aW9uLWdyb3VwczBeDBpncm91cC5jb20ud3VsdHJhLnRlc3RHcm91cAxAZ3JvdXAuQ1ktMEZDMzEwNUMtRUY2RC0xMUU5LTgyM0ItMzMxMzc0MDhCQzk2LmNvbS5jeWRpYS5FeHRlbmRlcjATDA5nZXQtdGFzay1hbGxvdwEB/zA5DBZrZXljaGFpbi1hY2Nlc3MtZ3JvdXBzMB8MDEtUVDlHODU5TVIuKgwPY29tLmFwcGxlLnRva2VuMIIGpQwSUHJvdmlzaW9uZWREZXZpY2VzMIIGjQwZMDAwMDgxMDEtMDAwNTI4RDkzQTEyMDAxRQwZMDAwMjelknfkjaerl;f</data> </array> <key>DER-Encoded-Profile</key> <data>UftjJiXcnphFtPME8RWgD9WFgMpfUPLE0HRxN12peXl28xXO0rVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFLuw3qFYM4iapIqZ3r6966/ayySrMEYGCCsGAQUFBwEBBDowODA2BggrBgEFBQcwAYYqaHR0cDovL29jc3AuYXBwbGUuY29tL29jc3AwMy1hcHBsZXJvb3RjYWczMDcGA1UdHwQwMC4wLKAqoCiGJmh0dHA6Ly9jcmwuYXBwbGUuY29tL2FwcGxlcm9vdGNhZzMuY3JsMB0GA1UdDgQWBBR6R7o4ihUkSCJGzb6PGiR7NAMqaTAOBgNVHQ8BAf8EBAMCQcm9kdWN0cyBhbmQvb3IgQXBwbGUgcHJvY2Vzc2VzLjAdBgNVHQ4EFgQUDgWBWc9LzVC4LP5b4EGBqz8zz+8wDgYDVR0PAQH/BAQDAgeAMA8GCSqGSIb3Y2QMEwQCBQAwCgYIKoZIzj0EAwIDRwAwRAIgSl19xJZLrQqOZYa8t493EpwrI7/L2J8LhbwYpW7gO80CIGiD58K1x1h1Cp43EHeyVRIYiVBThZVwbxWxLF7W8pwuMYIB1zCCAdMCAQEwfjByMSYwJAYDVQQDDB1BcHBsZSBTeXN0ZW0gSW50ZWdyYXRpb24gQ0EgNDEmMCQGA1UECwwdQXBwbGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxEzARBgNVBAoMCkFwcGxlIEluYy4xCzAJBgNVBAYTAlVTAggQZ+4OarG1YjANBglghkgBZQMEAgEFAKCB6TAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0yNDAxMDgxMDU5MTdaMCoGCSqGSIb3DQEJNDEdMBswDQYJYIZIAWUDBAIBBQChCgYIKoZIzj0EAwIwLwYJKoZIhvcNAQkEMSIEIMRi+YCgI1wI14ztb05ZvyGPMqw3KEKsLMcwLVtJ6yC7MFIGCSqGSIb3DQEJDzFFMEMwCgYIKoZIhvcNAwcwDgYIKoZIhvcNAwICAgCAMA0GCCqGSIb3DQMCAgFAMAcGBSsOAwIHMA0GCCqGSIb3DQMCAgEoMAoGCCqGSM49BAMCBEcwRQIhAMc5IyUcaFaKFEyjmo7hMiMGYYg6m+iJnLY6M4vc88yhAiB94O5nW+8T9zaGzCOB2Ey8VWEKTioOPyOSc8GZVntlHQ==</data> <key>Entitlements</key> <dict> \(entry) <key>com.apple.security.application-groups</key> <array> <string>group.com.wultra.testGroup</string> </array> <key>application-identifier</key> <string>ASDASDASD.com.wultra.test</string> <key>keychain-access-groups</key> <array> <string>ASDASDASD.*</string> <string>com.apple.token</string> </array> <key>get-task-allow</key> <true/> <key>com.apple.developer.team-identifier</key> <string>ASDASDASD</string> </dict> <key>ExpirationDate</key> <date>2025-01-07T10:59:17Z</date> <key>Name</key> <string>iOS Team Provisioning Profile: com.wultra.test</string> <key>ProvisionedDevices</key> <array> <string>00008101-000528D93A12001E</string> <string>00008101-001C34EC2250801E</string> <string>00008030-000975CC0AEA802E</string> <string>00008101-001269DE0A50001E</string> </array> <key>TeamIdentifier</key> <array> <string>ASDASDASD</string> </array> <key>TeamName</key> <string>Wultra</string> <key>TimeToLive</key> <integer>365</integer> <key>UUID</key> <string>7749747f-897e-45f3-b78e-d327a1c9f38a</string> <key>Version</key> <integer>1</integer> </dict> </plist>".data(using: .utf8)!
    }
}
