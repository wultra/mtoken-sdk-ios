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
            token: token.toHex(),
            environment: getPushEnvironment(environment: .automatic),
            completion: completion
        )
    }
    
    @discardableResult
    func register(to platform: WMTPushPlatform, completion: @escaping (Result<Void, WMTError>) -> Void) -> Operation? {
        
        let payloadPlatform: WMTPushRegistrationPlatform
        let payloadToken = platform.token
        let payloadEnvironment: WMTPushRegistrationEnvironment?
        
        switch platform {
        case .apns(_, let environment):
            payloadPlatform = .apns
            payloadEnvironment = getPushEnvironment(environment: environment)
        case .fcm:
            payloadPlatform = .fcm
            payloadEnvironment = nil // no env for FCM
        }
        
        D.info("Registering push for \(payloadPlatform.rawValue) platform.")
        
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
            D.info("Using APNS development environment for push notifications.")
            return .development
        case .production:
            D.info("Using APNS production environment for push notifications.")
            return .production
        case .automatic:
            let env = WMTProvisioningUtils.getMainProvisioningProfile()?.apnsEnvironment ?? WMTSignatureAPNSEnvironmentDetector.detectAPNSEnvironment()
            if let env {
                D.info("Using \(env) environment for push notifications (automatic resolution).")
            } else {
                D.warning("No APNS environment found in provisioning profile. Server configuration will be used.")
            }
            return env
        }
    }
}

extension WMTPushPlatform {
    var token: String {
        return switch self {
        case .apns(token: let token, environment: _): token.toHex()
        case .fcm(token: let token): token
        }
    }
}
