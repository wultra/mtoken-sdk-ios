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
/// push notifications
public protocol WMTPush: class {
    /// If there was already made an successful request
    var pushNotificationsRegisteredOnServer: Bool { get }
    
    /// Configuration for the service
    var config: WMTConfig { get }
    
    /// Accept language for the outgoing requests headers.
    /// Default value is "en".
    ///
    /// Response texts are based on this setting. For example when "de" is set, server
    /// will sent notifications in german.
    var acceptLanguage: String { get set }
    
    /// Registers the current powerauth activation for push notifications
    ///
    /// - Parameters:
    ///   - token: push token
    ///   - completionHandler: completion handler
    @discardableResult
    func registerDeviceTokenForPushNotifications(token: Data, completionHandler: @escaping (_ success: Bool, _ error: WMTError?) -> Void) -> Operation?
}
