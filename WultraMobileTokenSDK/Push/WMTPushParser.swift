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
import UserNotifications

/// Helper class that can translate incoming notifications from APNS to WMT push message.s
public class WMTPushParser {
    
    /// When you receive a push notification, you can test it here if it's a "WMT" notification.
    ///
    /// - Parameter notification: notification obtained via UNUserNotificationCenter
    /// - Returns: returns a parsed known WMT message or nil
    public static func parseNotification(_ notification: UNNotification) -> WMTPushMessage? {
        return parseNotification(notification.request.content.userInfo)
    }
    
    /// When you receive a push notification, you can test it here if it's a "WMT" notification.
    ///
    /// - Parameter userInfo: user info of received notification
    /// - Returns: returns a parsed known WMT message or nil
    public static func parseNotification(_ userInfo: [AnyHashable: Any]) -> WMTPushMessage? {
        
        guard let messageType = userInfo["messageType"] as? String,
              let operationId = userInfo["operationId"] as? String,
            let operationName = userInfo["operationName"] as? String else {
                return nil
        }
        
        switch messageType {
        case "mtoken.operationInit":
            
            var content: WMTPushContent?
            
            if let alert = (userInfo["aps"] as? NSDictionary)?["alert"] as? NSDictionary,
               let title = alert["title"] as? String,
               let body = alert["body"] as? String {
                
                content = (title, body)
            }
            
            return .operationCreated(id: operationId, name: operationName, content: content)
        case "mtoken.operationFinished":
            guard let result = userInfo["mtokenOperationResult"] as? String else {
                return nil
            }
            let opResult: WMTPushOperationFinishedResult
            switch result {
            case "authentication.success": opResult = .success
            case "authentication.fail": opResult = .fail
            case "operation.timeout": opResult = .timeout
            case "operation.canceled": opResult = .canceled
            case "operation.methodNotAvailable": opResult = .methodNotAvailable
            default: opResult = .unknown
            }
            return .operationFinished(id: operationId, name: operationName, result: opResult)
        default:
            return nil
        }
    }
}

/// Known push message.
public enum WMTPushMessage {
    /// A new operation was triggered.
    case operationCreated(id: String, name: String, content: WMTPushContent?)
    
    /// An operation was finished, successfully or non-successfully.
    case operationFinished(id: String, name: String, result: WMTPushOperationFinishedResult)
}

/// Action which finished the operation.
public enum WMTPushOperationFinishedResult {
    /// Operation was successfully confirmed.
    case success
    /// Operation failed to confirm.
    case fail
    /// Operation expired.
    case timeout
    /// Operation was cancelled by the user.
    case canceled
    /// mToken authentication method was removed from the user.
    /// This is very rare case.
    case methodNotAvailable
    /// Unknown result.
    case unknown
}

public typealias WMTPushContent = (title: String, message: String)
