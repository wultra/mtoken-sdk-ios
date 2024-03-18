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

/// Protocol for service, that communicates with Mobile Token API that handles operation approving
/// via powerauth protocol.
public protocol WMTOperations: AnyObject {
    
    /// Delegate gets notified about changes in operations loading.
    /// Methods of the delegate are always called on the main thread.
    var delegate: WMTOperationsDelegate? { get set }
    
    /// Configuration of the polling feature
    var pollingOptions: WMTOperationsPollingOptions { get }
    
    /// Accept language for the outgoing requests headers.
    /// Default value is "en".
    ///
    /// Standard RFC "Accept-Language" https://tools.ietf.org/html/rfc7231#section-5.3.5
    /// Response texts are based on this setting. For example when "de" is set, server
    /// will return operation texts in german (if available).
    var acceptLanguage: String { get set }
    
    /// Last cached operation result for easy access.
    var lastFetchResult: GetOperationsResult? { get }
    
    /// If operation loading is currently in progress.
    var isLoadingOperations: Bool { get }
    
    /// Refreshes operations, but does not return any result. For the result, you can
    /// add a delegate to `delegate` property.
    /// If operations are already loading, the function does nothing.
    func refreshOperations()
    
    /// Retrieves user operations and calls task when finished.
    ///
    /// - Parameter completion: To be called when operations are loaded.
    ///                         This completion is always called on the main thread.
    /// - Returns: Control object in case the operations needs to be canceled.
    @discardableResult
    func getOperations(completion: @escaping GetOperationsCompletion) -> WMTCancellable
    
    /// Retrieves the history of user operations with its current status.
    /// - Parameters:
    ///   - authentication: Authentication object for signing.
    ///   - completion: Result completion.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    @discardableResult
    func getHistory(authentication: PowerAuthAuthentication, completion: @escaping(Result<[WMTOperationHistoryEntry], WMTError>) -> Void) -> Operation?
    
    /// Retrieves operation detail based on operation ID
    /// - Parameters:
    ///   - operationId: Operation ID to get
    ///   - completion: Result completion.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    @discardableResult
    func getDetail(operationId: String, completion: @escaping(Result<WMTUserOperation, WMTError>) -> Void) -> Operation?
    
    /// Assigns the 'non-personalized' operation to the user
    /// - Parameters:
    ///   - operationId: Operation ID which will be claimed to belong to the user
    ///   - completion: Result completion.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    @discardableResult
    func claim(operationId: String, completion: @escaping(Result<WMTUserOperation, WMTError>) -> Void) -> Operation?
    
    /// Authorize operation with given PowerAuth authentication object.
    ///
    /// - Parameters:
    ///   - operation: Operation that should  be authorized.
    ///   - authentication: Authentication object for signing.
    ///   - completion: Result callback.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    @discardableResult
    func authorize(operation: WMTOperation, with: PowerAuthAuthentication, completion: @escaping(Result<Void, WMTError>) -> Void) -> Operation?
    
    /// Will sign the given QR operation with URI ID and authentication object.
    ///
    /// Note that the operation will be signed even if the authentication object is
    /// not valid as it cannot be verified on the server.
    ///
    /// - Parameters:
    ///   - qrOperation: QR operation data.
    ///   - uriId: Custom signature URI ID of the operation. Use URI ID under which the operation was
    ///            created on the server. Usually something like `/confirm/offline/operation`.
    ///   - authentication: Authentication object for signing.
    ///   - completion: Result completion.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    @discardableResult
    func authorize(qrOperation: WMTQROperation, uriId: String, authentication: PowerAuthAuthentication, completion: @escaping(Result<String, WMTError>) -> Void) -> Operation
    
    /// Reject operation with a reason.
    ///
    /// - Parameters:
    ///   - operation: Operation that should be rejected.
    ///   - reason: Reason for the rejection.
    ///   - completion: Result callback.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    @discardableResult
    func reject(operation: WMTOperation, with: WMTRejectionReason, completion: @escaping(Result<Void, WMTError>) -> Void) -> Operation?
    
    /// If the service is polling operations
    var isPollingOperations: Bool { get }
    
    /// Starts the operations polling.
    ///
    /// If operations are already polling this call is ignored and
    /// polling interval won't be changed.
    /// - Parameter interval: Polling interval, minimum is 5s
    /// - Parameter delayStart: When true, polling starts after
    ///                         the first `interval` time passes
    func startPollingOperations(interval: TimeInterval, delayStart: Bool)
    
    /// Stops the operations polling.
    func stopPollingOperations()
}

public extension WMTOperations {
    
    /// Will sign the given QR operation with authentication object.
    ///
    /// Default operation URI ID `/operation/authorize/offline` is used. To customize this value, use
    /// the method with `uriId` parameter.
    ///
    /// Note that the operation will be signed even if the authentication object is
    /// not valid as it cannot be verified on the server.
    ///
    /// - Parameters:
    ///   - qrOperation: QR operation data
    ///   - authentication: Authentication object for signing.
    ///   - completion: Result completion.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    func authorize(qrOperation: WMTQROperation, authentication: PowerAuthAuthentication, completion: @escaping (Result<String, WMTError>) -> Void) -> Operation {
        return authorize(qrOperation: qrOperation, uriId: "/operation/authorize/offline", authentication: authentication, completion: completion)
    }
    
    /// Starts the operations polling.
    ///
    /// Deafula implementation of startPollingOperations
    /// The `interval` is set to 7 seconds, with a minimum value of 5 seconds.
    ///
    /// - Parameters:
    ///   - interval: Default is set to 7 seconds, with a minimum value of 5 seconds.
    ///   - delayStart: Default is set to true. Polling starts after the first `interval` time passes
    func startPollingOperations() {
        return startPollingOperations(interval: 7, delayStart: true)
    }
}

public typealias GetOperationsResult = Result<[WMTUserOperation], WMTError>
public typealias GetOperationsCompletion = (GetOperationsResult) -> Void

/// Delegate for WMTOperations service
public protocol WMTOperationsDelegate: AnyObject {
    
    /// When operations has changed
    ///
    /// - Parameters:
    ///   - operations: current state of the operations
    ///   - removed: removed operation since the last call
    ///   - added: added operations since the last call
    func operationsChanged(operations: [WMTUserOperation], removed: [WMTUserOperation], added: [WMTUserOperation])
    
    /// When operations failed to load
    ///
    /// - Parameter error: error with more details
    func operationsFailed(error: WMTError)
    
    /// Called when operation loading is started or stopped
    ///
    /// - Parameter loading: if the get operation request is in progress
    func operationsLoading(loading: Bool)
}

/// Configuration of the polling feature
public struct WMTOperationsPollingOptions: OptionSet {
    
    /// Pause polling when the app goes to the background.
    ///
    /// The polling is paused on `willResignActiveNotification`.
    /// The polling is unpaused on `didBecomeActiveNotification`.
    @available(iOS 10, *) // due to the dependency on UIKit (iOS 10 is minimum target).
    public static let pauseWhenOnBackground = WMTOperationsPollingOptions(rawValue: 1 << 0)
    
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
