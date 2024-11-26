//
// Copyright 2024 Wultra s.r.o.
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

class WMTSignatureAPNSEnvironmentDetector {
    
    static func detectAPNSEnvironment() -> WMTPushRegistrationEnvironment? {
        
        D.debug("Parsing main bundle signature to get APNS Environment.")
        
        guard let executableName = Bundle.main.infoDictionary?[kCFBundleExecutableKey as String] as? String else {
            D.error("Could not read executable name from Info.plist")
            return nil
        }
        guard let executablePath = Bundle.main.path(forResource: executableName, ofType: nil) else {
            D.error("Could not find executable \(executableName)")
            return nil
        }
        
        guard let cmsList = MachOReader.readSignatures(executablePath) else {
            D.error("Could not read signatures from \(executablePath)")
            return nil
        }
        
        guard cmsList.isEmpty == false else {
            D.info("Executable is not signed.")
            return nil
        }
        
        for cms in cmsList {
            
            if let apnsEnvironment = cms.entitlemens?.value(forKey: .apsEnvironment) as? String {
                switch apnsEnvironment {
                case "development":
                    D.debug("Development entitlement found in the app signature")
                    return .development
                case "production":
                    D.debug("Production entitlement found in the app signature")
                    return .production
                default:
                    D.debug("Unknown entitlement found in the app signature: \(apnsEnvironment)")
                }
            }
            
            guard let pkcs = cms.pkcs else {
                D.error("Could not read CMS signature")
                return nil
            }
            
            guard pkcs.certificates.count == 3 else {
                D.error("Invalid CMS signature count")
                return nil
            }
            
            if pkcs.certificates.contains(where: { $0.subjectDistinguishedName == KnownCertificates.appleICAname }) && pkcs.certificates.contains(where: { $0.subjectDistinguishedName == KnownCertificates.appleOASname }) {
                D.debug("App is signed with Apple's iOS Development Certificate - assuming production APNS environment")
                return .production
            }
            
            if pkcs.certificates.contains(where: { $0.subjectDistinguishedName == KnownCertificates.appleTFBname }) {
                D.debug("App is signed with Apple's iOS TestFlight Beta Certificate - assuming production APNS environment")
                return .production
            }
        }
        
        return nil
    }
}

public struct KnownCertificates {
    static let appleICAname = "CN=Apple iPhone Certification Authority, OU=Certification Authority, O=Apple Inc., C=US"
    static let appleOASname = "CN=Apple iPhone OS Application Signing, OU=iPhone, O=Apple Inc., C=US"
    static let appleTFBname = "CN=TestFlight Beta Distribution, OU=TESTFLIGHT, O=Apple Inc., C=US"
}
