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

import Foundation
import PowerAuth2
import WultraPowerAuthNetworking

public extension PowerAuthSDK {
    
    /// Creates instance of the `WMTPush` on top of the PowerAuth instance.
    /// - Parameter config: Push service config
    /// - Returns: Push service
    func createWMTPush(config: WMTConfig) -> WMTPush {
        return WMTPushImpl(powerAuth: self, config: config)
    }
}

public extension WMTErrorReason {
    /// Push registration is already in progress.
    static let push_alreadyRegistering = WMTErrorReason(rawValue: "push_alreadyRegistering")
}

class WMTPushImpl: WMTPush {
    
    // Dependencies
    private let powerAuth: PowerAuthSDK
    private let networking: WPNNetworkingService
    let config: WMTConfig
    
    private(set) var pushNotificationsRegisteredOnServer = false // Contains true if push notifications were already registered
    private var pendingRegistrationForRemotePushNotifications = false // Contains true if there's pending registration for push notifications
    
    var acceptLanguage: String {
        get { networking.acceptLanguage }
        set { networking.acceptLanguage = newValue }
    }
    
    init(powerAuth: PowerAuthSDK, config: WMTConfig) {
        self.powerAuth = powerAuth
        self.networking = WPNNetworkingService(powerAuth: powerAuth, config: config.wpnConfig, serviceName: "WMTPush")
        self.config = config
    }
    
    @discardableResult
    func registerDeviceTokenForPushNotifications(token: Data, completionHandler: @escaping (_ success: Bool, _ error: WMTError?) -> Void) -> Operation? {
        
        guard powerAuth.hasValidActivation() else {
            DispatchQueue.main.async {
                completionHandler(false, WMTError(reason: .missingActivation))
            }
            return nil
        }
        guard pendingRegistrationForRemotePushNotifications == false else {
            DispatchQueue.main.async {
                completionHandler(false, WMTError(reason: .push_alreadyRegistering))
            }
            return nil
        }
        
        let auth = PowerAuthAuthentication()
        auth.usePossession = true
        
        pendingRegistrationForRemotePushNotifications = true
        pushNotificationsRegisteredOnServer = false
        
        let data = WMTPushRegistrationData(token: HexadecimalString.encodeData(token))
        
        return networking.post(data: .init(data), signedWith: auth, to: WMTPushEndpoints.RegisterDevice.endpoint) { _, error in
            self.pendingRegistrationForRemotePushNotifications = false
            if error == nil {
                self.pushNotificationsRegisteredOnServer = true
                completionHandler(true, nil)
            } else {
                self.pushNotificationsRegisteredOnServer = false
                completionHandler(false, error)
            }
        }
    }
}

private class HexadecimalString {
    
    static let toHexTable: [Character] = [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F" ]
    
    static func encodeData(_ data: Data) -> String {
        var result = ""
        result.reserveCapacity(data.count * 2)
        for byte in data {
            let byteAsUInt = Int(byte)
            result.append(toHexTable[byteAsUInt >> 4])
            result.append(toHexTable[byteAsUInt & 15])
        }
        return result
    }
    
}
