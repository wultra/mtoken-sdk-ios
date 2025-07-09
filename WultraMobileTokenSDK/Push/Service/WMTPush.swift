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
import WultraPowerAuthNetworking

public class WMTPush: WMTService {
    
    // Dependencies
    let networking: WPNNetworkingService
    
    /// If there was already made an successful request.
    public private(set) var pushNotificationsRegisteredOnServer = false // Contains true if push notifications were already registered
    private var pendingRegistrationForRemotePushNotifications = false // Contains true if there's pending registration for push notifications
    
    /// Accept language for the outgoing requests headers.
    /// Default value is "en".
    /// Changing this value updates the accept language of the underlying networking service.
    ///
    /// Standard RFC "Accept-Language" https://tools.ietf.org/html/rfc7231#section-5.3.5
    /// Response texts are based on this setting. For example when "de" is set, server
    /// will return operation texts in german (if available).
    public var acceptLanguage: String {
        get { networking.acceptLanguage }
        set { networking.acceptLanguage = newValue }
    }
    
    public init(networking: WPNNetworkingService) {
        self.networking = networking
    }
    
    /// Registers the current powerauth activation for push notifications.
    ///
    /// This method is compatible with server stack `1.9.x`
    ///
    /// - Parameters:
    ///   - token: Push token.
    ///   - completion: Completion handler.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
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
    
    /// Registers the current Powerauth activation for push notifications.
    ///
    /// This method is compatible with server stack `1.10.x` and higher
    ///
    /// - Parameters:
    ///   - platform: Platform that you're registering to
    ///   - completion: Completion handler.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
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
            let env = WMTProvisioningUtils.getMainProvisioningProfile()?.entitlements.apsEnvironment ?? WMTSignatureAPNSEnvironmentDetector.detectAPNSEnvironment()?.apsEnvironment
            if let env {
                D.info("Using \(env) environment for push notifications (automatic resolution).")
            } else {
                D.warning("No APNS environment found in provisioning profile. Server configuration will be used.")
            }
            return env?.serverObject
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
