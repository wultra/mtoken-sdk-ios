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

internal class Entitlements {

    enum Key: String {
        case autofillCredentialProvider = "com.apple.developer.authentication-services.autofill-credential-provider"
        case signWithApple = "com.apple.developer.applesignin"
        case contacts = "com.apple.developer.contacts.notes"
        case classKit = "com.apple.developer.ClassKit-environment"
        case automaticAssesmentConfiguration = "com.apple.developer.automatic-assessment-configuration"
        case gameCenter = "com.apple.developer.game-center"
        case healthKit = "com.apple.developer.healthkit"
        case healthKitCapabilities = "com.apple.developer.healthkit.access"
        case homeKit = "com.apple.developer.homekit"
        case iCloudDevelopmentContainersIdentifiers = "com.apple.developer.icloud-container-development-container-identifiers"
        case iCloudContainersEnvironment = "com.apple.developer.icloud-container-environment"
        case iCloudContainerIdentifiers = "com.apple.developer.icloud-container-identifiers"
        case iCloudServices = "com.apple.developer.icloud-services"
        case iCloudKeyValueStore = "com.apple.developer.ubiquity-kvstore-identifier"
        case interAppAudio = "inter-app-audio"
        case networkExtensions = "com.apple.developer.networking.networkextension"
        case personalVPN = "com.apple.developer.networking.vpn.api"
        case apsEnvironment = "aps-environment"
        case appGroups = "com.apple.security.application-groups"
        case keychainAccessGroups = "keychain-access-groups"
        case dataProtection = "com.apple.developer.default-data-protection"
        case siri = "com.apple.developer.siri"
        case passTypeIDs = "com.apple.developer.pass-type-identifiers"
        case merchantIDs = "com.apple.developer.in-app-payments"
        case wifiInfo = "com.apple.developer.networking.wifi-info"
        case externalAccessoryConfiguration = "com.apple.external-accessory.wireless-configuration"
        case multipath = "com.apple.developer.networking.multipath"
        case hotspotConfiguration = "com.apple.developer.networking.HotspotConfiguration"
        case nfcTagReaderSessionFormats = "com.apple.developer.nfc.readersession.formats"
        case associatedDomains = "com.apple.developer.associated-domains"
        case maps = "com.apple.developer.maps"
        case driverKit = "com.apple.developer.driverkit.transport.pci"
    }

    private let values: [String: Any]
    
    init?(_ data: Data) {
        guard let rawValues = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            return nil
        }
        self.values = rawValues
    }

    func value(forKey key: Entitlements.Key) -> Any? {
        values[key.rawValue]
    }
}
