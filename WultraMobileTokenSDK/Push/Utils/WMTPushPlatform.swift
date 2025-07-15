//
// Copyright 2025 Wultra s.r.o.
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

/// Push platform that is used for push notifications
public enum WMTPushPlatform {

    /// Apple Push Notification Service - when you're using directly Apple Push Service for push notifications
    /// - Parameters:
    ///   - token: APNS push token data retrieved from the system
    ///   - environment: APNS push environment. Default value is `automatic`
    case apns(token: Data, environment: WMTPushAPNSEnvironment = .automatic)

    /// Firebase Cloud Messaging - when you're using Firebase to send push notifications
    /// - Parameters:
    ///   - token: FCM token retrieved from the Firebase SDK
    case fcm(token: String)
}
