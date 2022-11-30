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
    /// - Parameters:
    ///   - token: Push token.
    ///   - completion: Completion handler.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    @discardableResult
    func registerDeviceTokenForPushNotifications(token: Data, completion: @escaping (Result<Void, WMTError>) -> Void) -> Operation?
}
