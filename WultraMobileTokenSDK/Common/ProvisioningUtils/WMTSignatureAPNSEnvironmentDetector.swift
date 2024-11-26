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
    
    static func detectAPNSEnvironment() -> WMTProvision.Entitlements? {
        
        D.debug("Parsing main bundle signature to get APNS Environment.")
        
        guard let executableName = Bundle.main.infoDictionary?[kCFBundleExecutableKey as String] as? String else {
            D.error("Could not read executable name from Info.plist")
            return nil
        }
        guard let executablePath = Bundle.main.path(forResource: executableName, ofType: nil) else {
            D.error("Could not find executable \(executableName)")
            return nil
        }
        
        guard let entitlements = WMTMachOReader.readEntitlements(executablePath) else {
            D.error("Could not read entitlements from \(executablePath)")
            return nil
        }
        
        guard entitlements.isEmpty == false else {
            D.info("Not entitlements found")
            return nil
        }
        
        return entitlements.first(where: { $0.apsEnvironment != nil })
    }
}
