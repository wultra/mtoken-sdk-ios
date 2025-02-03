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

public class WMTPush: WMTService {
    
    // Dependencies
    lazy var powerAuth = networking.powerAuth
    let networking: WPNNetworkingService
    
    /// If there was already made an successful request.
    public private(set) var pushNotificationsRegisteredOnServer = false // Contains true if push notifications were already registered
    private var pendingRegistrationForRemotePushNotifications = false // Contains true if there's pending registration for push notifications
    
    /// Accept language for the outgoing requests headers.
    public var acceptLanguage: String {
        get { networking.acceptLanguage }
        set { networking.acceptLanguage = newValue }
    }
    
    public init(networking: WPNNetworkingService) {
        self.networking = networking
    }
    
    /// Registers the current powerauth activation for push notifications.
    ///
    /// - Parameters:
    ///   - token: Push token.
    ///   - completion: Completion handler.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    @discardableResult
    public func registerDeviceTokenForPushNotifications(token: Data, completion: @escaping (Result<Void, WMTError>) -> Void) -> Operation? {
        
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
        
        let data = WMTPushRegistrationData(token: WMTHexadecimalString.encodeData(token))
        
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
}
