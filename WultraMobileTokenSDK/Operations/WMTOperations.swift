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
public protocol WMTOperations: class {
    
    /// Delegate gets notified about changes in operations loading.
    var delegate: WMTOperationsDelegate? { get set }
    
    /// Configuration for the service
    var config: WMTConfig { get }
    
    /// Accept language for the outgoing requests headers.
    /// Default value is "en".
    ///
    /// Standard RFC "Accept-Language" https://tools.ietf.org/html/rfc7231#section-5.3.5
    /// Response texts are based on this setting. For example when "de" is set, server
    /// will return operation texts in german (if available).
    var acceptLanguage: String { get set }
    
    /// Last cached operation result for easy access
    var lastFetchResult: GetOperationsResult? { get }
    
    /// If operation loading is currently in progress
    var isLoadingOperations: Bool { get }
    
    /// Refreshes operations, but does not return any result. For the result, you can
    /// add a delegate to `delegate` property.
    /// If operations are already loading, the function does nothing.
    func refreshOperations()
    
    /// Retrieves user operations and calls task when finished
    ///
    /// - Parameter completion: to be called when operations are loaded
    ///
    /// Note: be sure to call this method on Main Thread!
    func getOperations(completion: @escaping GetOperationsCompletion) -> Cancellable
    
    /// Authorize operation with given PowerAuth authentication object.
    ///
    /// - Parameters:
    ///   - operation: operation that should  be authorized
    ///   - authentication: authentication object for signing
    ///   - completion: result callback (nil on success)
    @discardableResult
    func authorize(operation: WMTOperation, authentication: PowerAuthAuthentication, completion: @escaping(WMTError?)->Void) -> Operation?
    
    /// Will sign the given QR operation with authentication object.
    ///
    /// Note that the operation will be signed even if the authentication object is
    /// not valid as it cannot be verified on the server.
    ///
    /// - Parameters:
    ///   - qrOperation: QR operation data
    ///   - authentication: authentication object for signing
    ///   - completion: result completion
    /// - Returns: operation for state observation
    @discardableResult
    func authorize(qrOperation: WMTQROperation, authentication: PowerAuthAuthentication, completion: @escaping(Result<String, WMTError>) -> Void) -> Operation
    
    /// Reject operation with a reason.
    ///
    /// - Parameters:
    ///   - operation: operation that should be rejected
    ///   - reason: reason for rejection
    ///   - completion: result callback (nil on success)
    @discardableResult
    func reject(operation: WMTOperation, reason: WMTRejectionReason, completion: @escaping(WMTError?)->Void) -> Operation?
    
    /// If the service is polling operations
    var isPollingOperations: Bool { get }
    
    /// Start the operations polling.
    /// Note that if operations are already polling, this call is ignored and
    /// polling interval won't be changed.
    func startPollingOperations(interval: TimeInterval)
    
    /// Stops the operations polling
    func stopPollingOperations()
}

public typealias GetOperationsResult = Result<[WMTUserOperation], WMTError>
public typealias GetOperationsCompletion = (GetOperationsResult) -> Void

public protocol Cancellable: class {
    var isCanceled: Bool { get }
    func cancel()
}

/// Delegate for WMTOperations service
public protocol WMTOperationsDelegate: class {
    
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
