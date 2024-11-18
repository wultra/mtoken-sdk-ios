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
    
    static func parseProvisioningProfile(_ profile: Data) -> WMTProvision? {
        do {
            let provision = try PropertyListDecoder().decode(WMTProvision.self, from: profile)
            return provision
        } catch let e {
            D.error("Failed to parse provisioning profile: \(e)")
            return nil
        }
    }
    
    static func getMainProvisioningProfile() -> WMTProvision? {
        guard let filePath = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") else {
            D.debug("Missing embedded provisioning profile in the main bundle.")
            return nil
        }
        let url = URL(fileURLWithPath: filePath)
        do {
            let data = try Data(contentsOf: url)
            guard let string = String(data: data, encoding: .isoLatin1) else {
                D.error("Failed to decode provisioning profile data in ISO Latin 1.")
                return nil
            }
            let scanner = Scanner(string: string as String)
            guard scanner.scanUpTo("<plist", into: nil) != false else {
                D.error("Search for provisioning profile plist start tag failed.")
                return nil
            }
             
            var extractedPlist: NSString?
            guard scanner.scanUpTo("</plist>", into: &extractedPlist) != false else {
                D.error("Search for provisioning profile plist end tag failed.")
                return nil
            }
             
            guard let plist = extractedPlist?.appending("</plist>").data(using: .isoLatin1) else {
                D.error("Failed to convert provisioning profile plist to data.")
                return nil
            }

            return parseProvisioningProfile(plist)
        } catch let e {
            D.error("Failed to load provisioning profile: \(e)")
            return nil
        }
    }
}

/// Provisioning profile plist structure. Note that we need only entitlements for now.
/// The rest of the struct is commented out in case something changes so it does not break the parser unnecesarilly
struct WMTProvision: Decodable {
    /*
    var name: String
    var appIDName: String
    var platform: [String]
    var isXcodeManaged: Bool? = false
    var creationDate: Date
    var expirationDate: Date
     */
    var entitlements: Entitlements
    
    private enum CodingKeys: String, CodingKey {
        /*
        case name = "Name"
        case appIDName = "AppIDName"
        case platform = "Platform"
        case isXcodeManaged = "IsXcodeManaged"
        case creationDate = "CreationDate"
        case expirationDate = "ExpirationDate"
        */
        case entitlements = "Entitlements"
    }
    
    struct Entitlements: Decodable {
        /*
        let keychainAccessGroups: [String]
        let getTaskAllow: Bool
        */
        let apsEnvironment: Environment?
        
        private enum CodingKeys: String, CodingKey {
            /*
            case keychainAccessGroups = "keychain-access-groups"
            case getTaskAllow = "get-task-allow"
            */
            case apsEnvironment = "aps-environment"
        }
        
        enum Environment: String, Decodable {
            case development
            case production
        }
        
        init(/*keychainAccessGroups: [String], getTaskAllow: Bool,*/ apsEnvironment: Environment?) {
            /*
            self.keychainAccessGroups = keychainAccessGroups
            self.getTaskAllow = getTaskAllow
            */
            self.apsEnvironment = apsEnvironment
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            /*
            let keychainAccessGroups: [String] = (try? container.decode([String].self, forKey: .keychainAccessGroups)) ?? []
            let getTaskAllow: Bool = (try? container.decode(Bool.self, forKey: .getTaskAllow)) ?? false
            */
            let apsEnvironment = try? container.decode(Environment.self, forKey: .apsEnvironment)
            
            self.init(/*keychainAccessGroups: keychainAccessGroups, getTaskAllow: getTaskAllow,*/ apsEnvironment: apsEnvironment)
        }
    }
}
