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

/// Protocol for service, that communicates with Mobile Token API that handles registration for
/// push notifications.
public protocol WMTPush: AnyObject {
    /// If there was already made an successful request.
    var pushNotificationsRegisteredOnServer: Bool { get }
    
    /// Accept language for the outgoing requests headers.
    /// Default value is "en".
    var acceptLanguage: String { get set }
    
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
    @available(*, deprecated, renamed: "register", message: "This method is deprecated since server version 1.10.0. Use register(token:completion:) instead.")
    func registerDeviceTokenForPushNotifications(token: Data, completion: @escaping (Result<Void, WMTError>) -> Void) -> Operation?
    
    /// Registers the current powerauth activation for push notifications.
    ///
    /// - Parameters:
    ///   - platform: Platform that you're registering to
    ///   - completion: Completion handler.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    @discardableResult
    func register(to platform: WMTPushPlatform, completion: @escaping (Result<Void, WMTError>) -> Void) -> Operation?
}

/// Push platform that is used for push notifications
public enum WMTPushPlatform {
    
    /// Apple Push Notification Service - when you're using directly Apple Push Service for push notifications
    /// - Parameters:
    ///   - token: APNS push token data retrieved from the system
    case apns(token: Data)
    
    /// Firebase Cloud Messaging - when you're using Firebase to send push notifications
    /// - Parameters:
    ///   - token: FCM token retrieved from the Firebase SDK
    case fcm(token: String)
}
