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
    func getUnreadCount(completion: @escaping(Result<WMTInboxCount, WMTError>) -> Void) -> Operation?
    
    /// Paged list of messages in the inbox. You can use also `getAllMessages()` method to fetch all messages.
    ///
    /// - Parameters:
    ///   - pageNumber: Page number.
    ///   - pageSize: Size of the page.
    ///   - onlyUnread" Get only unread messages.
    ///   - completion: Result callback.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    @discardableResult
    func getMessageList(pageNumber: Int, pageSize: Int, onlyUnread: Bool, completion: @escaping(Result<[WMTInboxMessage], WMTError>) -> Void) -> Operation?
    
    /// Message detail in the inbox.
    ///
    /// - Parameters:
    ///   - messageId: Message ID.
    ///   - completion: Result callback.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    @discardableResult
    func getMessageDetail(messageId: String, completion: @escaping(Result<WMTInboxMessageDetail, WMTError>) -> Void) -> Operation?
    
    /// Marks the given message as read.
    ///
    /// - Parameters:
    ///   - messageId: Message ID.
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
    func markAllRead(completion: @escaping(Result<Void, WMTError>) -> Void) -> Operation?
}

public extension WMTInbox {
    /// Get all messages in the inbox. The function will issue multiple HTTP requests until the list is not complete.
    ///
    /// - Parameters:
    ///   - pageSize: How many messages should be fetched at once. The default value is 100.
    ///   - messageLimit:Maximum number of messages to be retrieved. Use 0 to set no limit. The default value is 1000.
    ///   - onlyUnread: If `true` then only unread messages will be returned. The default value is `false`.
    ///   - completion: Result callback. This completion is always called on the main thread.
    ///
    /// - Returns: Operation object for its state observation.
    @discardableResult
    func getAllMessages(pageSize: Int = 100, messageLimit: Int = 1000, onlyUnread: Bool = false, completion: @escaping(Result<[WMTInboxMessage], WMTError>) -> Void) -> WMTCancellable? {
        let operation = FetchOperation(pageSize: pageSize, onlyUnread: onlyUnread, messageLimit: messageLimit, completion: completion)
        return fetchPartialList(fetchOperation: operation) == nil ? nil : operation
    }
    
    /// Fetch partial list from the server.
    /// - Parameters:
    ///   - pageNumber: Starting page number.
    ///   - pageSize: Size of page.
    ///   - messageLimit: Maximum number of messages to be retrieved.
    ///   - fetchOperation: Fetch operation that contains overall progress of getting messages.
    /// - Returns: Provided fetch operation or `nil` if function unable to get messages at this time.
    private func fetchPartialList(fetchOperation: FetchOperation) -> Operation? {
        let operation = self.getMessageList(pageNumber: fetchOperation.pageNumber, pageSize: fetchOperation.pageSize, onlyUnread: fetchOperation.onlyUnread) { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .success(let messages):
                guard !fetchOperation.isCanceled else {
                    // Operation is canceled, just ignore the result
                    return
                }
                // Append operations to the result and determine whether we're at the end of the list.
                if fetchOperation.appendPartialMessages(messages) {
                    // We're at the end of the list, or message limit reached.
                    fetchOperation.complete(.success(fetchOperation.readMessages))
                } else {
                    // We should fetch the next batch of messages.
                    fetchOperation.nestedOperation = self.fetchPartialList(fetchOperation: fetchOperation)
                    
                }
            case .failure:
                fetchOperation.complete(result)
            }
        }
        fetchOperation.nestedOperation = operation
        return operation
    }
}

/// Support class that allows fetch all messages at once.
private class FetchOperation: WMTCancellable {
    
    typealias ResultType = Result<[WMTInboxMessage], WMTError>
    
    private(set) var pageNumber: Int
    let pageSize: Int
    let onlyUnread: Bool
    let messageLimit: Int
    
    var nestedOperation: Operation?
    private(set) var readMessages: [WMTInboxMessage] = []
    
    private var cancelFlag = false
    private var finishFlag = false
    private let completion: (ResultType) -> Void
    
    /// Construct class with required parameters.
    /// - Parameters:
    ///   - pageSize: Page size.
    ///   - onlyUnread: Fetch only unread messages.
    ///   - messageLimit: Message limit.
    ///   - completion: Completion callback.
    init(pageSize: Int, onlyUnread: Bool, messageLimit: Int, completion: @escaping (ResultType) -> Void) {
        self.pageNumber = 0
        self.pageSize = pageSize
        self.onlyUnread = onlyUnread
        self.messageLimit = messageLimit
        self.completion = completion
    }
    
    /// Append received messages and determine whether we're at the end of the list.
    /// - Parameter messages: Partial messages received from the server.
    /// - Returns: `true` if we're at the end of the list.
    func appendPartialMessages(_ messages: [WMTInboxMessage]) -> Bool {
        readMessages.append(contentsOf: messages)
        pageNumber += 1
        return messages.count < pageSize || (messageLimit > 0 && readMessages.count > messageLimit)
    }
    
    /// Complete operation with result.
    /// - Parameter result: Result to report back to the application.
    func complete(_ result: ResultType) {
        guard !cancelFlag && !finishFlag else {
            return
        }
        finishFlag = true
        completion(result)
    }
    
    func cancel() {
        nestedOperation?.cancel()
        cancelFlag = true
    }
    
    var isCanceled: Bool {
        return cancelFlag
    }
}
