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

class WMTProvisioningUtils {
    
    static func parseProvisioningProfile(_ profile: Data) -> [String: String]? {
        do {
            let items = try PropertyListDecoder().decode([String: String].self, from: profile)
            return items
        } catch let e {
            D.error("Failedto parse provisioning profile: \(e)")
            return nil
        }
    }
    
    static func getMainProvisioningProfile() -> [String: String]? {
        guard let filePath = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") else {
            D.debug("Missing embedded provisioning profile in the main bundle.")
            return nil
        }
        let url = URL(fileURLWithPath: filePath)
        do {
            let data = try Data(contentsOf: url)
            return parseProvisioningProfile(data)
        } catch let e {
            D.error("Failed to load provisioning profile: \(e)")
            return nil
        }
    }
    
    static func getApnsEnvironment(profileDict: [String: String]?) -> WMTPushRegistrationEnvironment? {
        let value = profileDict?["aps-environment"]
        switch value {
        case "development":
            return  .development
        case "production":
            return .production
        case nil:
            return nil
        default:
            D.warning("Unknown APNS environment: \(value ?? "")")
            return nil
        }
    }
}
