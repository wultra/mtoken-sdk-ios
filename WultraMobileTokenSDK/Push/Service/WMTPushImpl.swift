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
    /// - Parameter networkingConfig: Networking service config
    /// - Returns: Push service
    func createWMTPush(networkingConfig: WPNConfig) -> WMTPush {
        return WMTPushImpl(networking: WPNNetworkingService(powerAuth: self, config: networkingConfig, serviceName: "WMTPush"))
    }
}

public extension WPNNetworkingService {
    
    /// Creates instance of the `WMTPush` on top of the WPNNetworkingService instance.
    /// - Returns: Push service
    func createWMTPush() -> WMTPush {
        return WMTPushImpl(networking: self)
    }
}

public extension WMTErrorReason {
    /// Push registration is already in progress.
    static let push_alreadyRegistering = WMTErrorReason(rawValue: "push_alreadyRegistering")
}

class WMTPushImpl: WMTPush, WMTService {
    
    // Dependencies
    lazy var powerAuth = networking.powerAuth
    let networking: WPNNetworkingService
    
    private(set) var pushNotificationsRegisteredOnServer = false // Contains true if push notifications were already registered
    private var pendingRegistrationForRemotePushNotifications = false // Contains true if there's pending registration for push notifications
    
    var acceptLanguage: String {
        get { networking.acceptLanguage }
        set { networking.acceptLanguage = newValue }
    }
    
    init(networking: WPNNetworkingService) {
        self.networking = networking
    }
    
    @discardableResult
    func registerDeviceTokenForPushNotifications(token: Data, completion: @escaping (Result<Void, WMTError>) -> Void) -> Operation? {
        // ios for backwards compatibility
        return registerPush(
            platform: .ios,
            token: HexadecimalString.encodeData(token),
            environment: getPushEnvironment(environment: .automatic),
            completion: completion
        )
    }
    
    @discardableResult
    func register(to platform: WMTPushPlatform, completion: @escaping (Result<Void, WMTError>) -> Void) -> Operation? {
        
        let payloadPlatform: WMTPushRegistrationPlatform
        let payloadToken: String
        let payloadEnvironment: WMTPushRegistrationEnvironment?
        
        switch platform {
        case .apns(let data, let environment):
            payloadPlatform = .apns
            payloadToken = HexadecimalString.encodeData(data)
            payloadEnvironment = getPushEnvironment(environment: environment)
        case .fcm(let token):
            payloadPlatform = .fcm
            payloadToken = token
            payloadEnvironment = nil // no env for FCM
        }
        
        return registerPush(platform: payloadPlatform, token: payloadToken, environment: payloadEnvironment, completion: completion)
    }
    
    private func registerPush(platform: WMTPushRegistrationPlatform, token: String, environment: WMTPushRegistrationEnvironment?, completion: @escaping (Result<Void, WMTError>) -> Void) -> Operation? {
        
        guard validateActivation(completion) else {
            return nil
        }
        
        guard pendingRegistrationForRemotePushNotifications == false else {
            DispatchQueue.main.async {
                completion(.failure(WMTError(reason: .push_alreadyRegistering)))
            }
            return nil
        }
        
        pendingRegistrationForRemotePushNotifications = true
        pushNotificationsRegisteredOnServer = false
        
        let data = WMTPushRegistrationData(platform: platform, token: token, environment: environment)
        
        return networking.post(data: .init(data), signedWith: .possession(), to: WMTPushEndpoints.RegisterDevice.endpoint) { _, error in
            self.pendingRegistrationForRemotePushNotifications = false
            if let error = error {
                self.pushNotificationsRegisteredOnServer = false
                completion(.failure(error))
            } else {
                self.pushNotificationsRegisteredOnServer = true
                completion(.success(()))
            }
        }
    }
    
    private func getPushEnvironment(environment: WMTPushAPNSEnvironment) -> WMTPushRegistrationEnvironment? {
        switch environment {
        case .development:
            return .development
        case .production:
            return .production
        case .automatic:
            return WMTProvisioningUtils.getApnsEnvironment(profile: WMTProvisioningUtils.getMainProvisioningProfile())
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
