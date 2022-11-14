//
// Copyright 2022 Wultra s.r.o.
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

/// Protocol for service that communicates with Inbox API that is managing user inbox.
public protocol WMTInbox: AnyObject {
    
    /// Accept language for the outgoing requests headers.
    /// Default value is "en".
    ///
    /// Standard RFC "Accept-Language" https://tools.ietf.org/html/rfc7231#section-5.3.5
    /// Response texts are based on this setting. For example when "de" is set, server
    /// will return operation texts in german (if available).
    var acceptLanguage: String { get set }
    
    /// Number of unread messages in the inbox
    ///
    /// - Parameters:
    ///   - completion: Result callback.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    @discardableResult
    func getUnreadCount(completion: @escaping(Result<WMTInboxUnread, WMTError>) -> Void) -> Operation?
    
    /// Page of messages in the inbox.
    ///
    /// - Parameters:
    ///   - pageNumber: Page number
    ///   - size: Size of the page
    ///   - completion: Result callback.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    @discardableResult
    func getPage(pageNumber: Int, size: Int, completion: @escaping(Result<WMTInboxPage, WMTError>) -> Void) -> Operation?
    
    /// Message in the inbox.
    ///
    /// - Parameters:
    ///   - id: Message ID
    ///   - completion: Result callback.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    @discardableResult
    func getMessage(id: String, completion: @escaping(Result<WMTInboxMessage, WMTError>) -> Void) -> Operation?
    
    /// Marks the given message as read.
    ///
    /// - Parameters:
    ///   - messageId: Message ID
    ///   - completion: Result callback.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    @discardableResult
    func markRead(messageId: String, completion: @escaping(Result<Void, WMTError>) -> Void) -> Operation?
    
    /// Marks all unread messages in the inboc as read.
    ///
    /// - Parameters:
    ///   - completion: Result callback.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    @discardableResult
    func markReadAll(completion: @escaping(Result<Void, WMTError>) -> Void) -> Operation?
}
