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

/// Helper class that can translate incoming notifications from APNS to WMTPushMessage.
public class WMTPushParser {
    
    /// When you receive a push notification, you can test it here if it's a "WMT" notification.
    ///
    /// - Parameter notification: notification obtained via UNUserNotificationCenter
    /// - Returns: returns a parsed known WMTPushMessage or nil
    public static func parseNotification(_ notification: UNNotification) -> WMTPushMessage? {
        return parseNotification(notification.request.content.userInfo)
    }
    
    /// When you receive a push notification, you can test it here if it's a "WMT" notification.
    ///
    /// - Parameter userInfo: user info of received notification
    /// - Returns: returns a parsed known WMTPushMessage or nil
    public static func parseNotification(_ userInfo: [AnyHashable: Any]) -> WMTPushMessage? {
        guard let messageType = userInfo["messageType"] as? String else {
            return nil
        }
        
        switch messageType {
        case "mtoken.operationInit":
            return parseOperationCreated(userInfo)
        case "mtoken.operationFinished":
            return parseOperationFinished(userInfo)
        case "mtoken.inboxMessage.new":
            return parseInboxMessage(userInfo)
        default:
            return nil
        }
    }

    // Helper methods
    private static func parseOperationCreated(_ userInfo: [AnyHashable: Any]) -> WMTPushMessage? {
        guard let operationId = userInfo["operationId"] as? String,
              let operationName = userInfo["operationName"] as? String else {
            return nil
        }

        var content: WMTPushContent?

        if let alert = (userInfo["aps"] as? NSDictionary)?["alert"] as? NSDictionary,
           let title = alert["title"] as? String,
           let body = alert["body"] as? String {
            content = (title, body)
        }

        return .operationCreated(id: operationId, name: operationName, content: content, originalData: userInfo)
    }

    private static func parseOperationFinished(_ userInfo: [AnyHashable: Any]) -> WMTPushMessage? {
        guard let operationId = userInfo["operationId"] as? String,
              let operationName = userInfo["operationName"] as? String,
              let result = userInfo["mtokenOperationResult"] as? String else {
            return nil
        }

        let opResult: WMTPushOperationFinishedResult
        switch result {
        case "authentication.success": opResult = .success
        case "authentication.fail": opResult = .fail
        case "operation.timeout": opResult = .timeout
        case "operation.canceled": opResult = .canceled
        case "operation.methodNotAvailable": opResult = .methodNotAvailable
        default: opResult = .unknown // to be forward compatible
        }

        return .operationFinished(id: operationId, name: operationName, result: opResult, originalData: userInfo)
    }

    private static func parseInboxMessage(_ userInfo: [AnyHashable: Any]) -> WMTPushMessage? {
        guard let inboxId = userInfo["inboxId"] as? String else {
            return nil
        }
        return .inboxMessageReceived(id: inboxId, originalData: userInfo)
    }
}

/// Known push message.
public enum WMTPushMessage {
    /// A new operation was triggered.
    case operationCreated(id: String, name: String, content: WMTPushContent?, originalData: [AnyHashable: Any])
    
    /// An operation was finished, successfully or non-successfully.
    case operationFinished(id: String, name: String, result: WMTPushOperationFinishedResult, originalData: [AnyHashable: Any])
    
    /// A new inbox message was triggered.
    case inboxMessageReceived(id: String, originalData: [AnyHashable: Any])
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
