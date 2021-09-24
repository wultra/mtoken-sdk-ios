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
import WultraPowerAuthNetworking
#if os(iOS)
import UIKit
#endif

public extension PowerAuthSDK {
    
    /// Creates instance of the `WMTOperations` on top of the PowerAuth instance.
    /// - Parameters:
    ///   - config: Operations service config
    ///   - pollingOptions: Polling feature configuration
    /// - Returns: Operations service
    func createWMTOperations(config: WMTConfig, pollingOptions: WMTOperationsPollingOptions = []) -> WMTOperations {
        return WMTOperationsImpl(powerAuth: self, config: config, pollingOptions: pollingOptions)
    }
}

public extension WMTErrorReason {
    /// Request needs valid powerauth activation.
    static let operations_invalidActivation = WMTErrorReason(rawValue: "operations_invalidActivation")
    /// Operation is already in failed a state.
    static let operations_alreadyFailed = WMTErrorReason(rawValue: "operations_alreadyFailed")
    /// Operation is already in finished a state.
    static let operations_alreadyFinished = WMTErrorReason(rawValue: "operations_alreadyFinished")
    /// Operation is already in canceled a state.
    static let operations_alreadyCanceled = WMTErrorReason(rawValue: "operations_alreadyCanceled")
    /// Operation expired.
    static let operations_alreadyRejected = WMTErrorReason(rawValue: "operations_expired")
    /// Operation has expired when trying to approve the operation.
    static let operations_authExpired = WMTErrorReason(rawValue: "operations_authExpired")
    /// Operation has expired when trying to reject the operation.
    static let operations_rejectExpired = WMTErrorReason(rawValue: "operations_rejectExpired")
    
    /// Couldn't sign QR operation.
    static let operations_QROperationFailed = WMTErrorReason(rawValue: "operations_QRFailed")
}

class WMTOperationsImpl: WMTOperations {
    
    // Dependencies
    private let powerAuth: PowerAuthSDK
    private let networking: WPNNetworkingService
    private let qrQueue: OperationQueue = {
        let q = OperationQueue()
        q.name = "WMTOperationsQRQueue"
        return q
    }()
    let config: WMTConfig
    
    /// If operation loading is currently in progress
    private(set) var isLoadingOperations = false {
        didSet {
            let val = isLoadingOperations
            delegate?.operationsLoading(loading: val)
        }
    }
    
    var isPollingOperations: Bool { return pollingLock.synchronized { self.isPollingOperationsInternal } }
    private var isPollingOperationsInternal: Bool { pollingTimer != nil }
    
    let pollingOptions: WMTOperationsPollingOptions
    
    var acceptLanguage: String {
        get { networking.acceptLanguage }
        set { networking.acceptLanguage = newValue }
    }
    
    private var tasks = [GetOperationsTask]() // Task that are waiting for operation fetch
    private var pollingTimer: Timer? // Timer that manages operations polling when requested
    private var isPollingPaused: Bool { return pollingTimer?.isValid == false }
    private let pollingLock = WMTLock()
    private var notificationObservers = [NSObjectProtocol]()
    
    /// Operation register holds operations in order
    private lazy var operationsRegister = OperationsRegister { [weak self] ops, added, removed in
        self?.delegate?.operationsChanged(operations: ops, removed: removed, added: added)
    }
    
    /// Last result of operation fetch.
    private(set) var lastFetchResult: GetOperationsResult?
    
    /// Delegate gets notified about changes in operations loading.
    /// Methods of the delegate are always called on the main thread.
    weak var delegate: WMTOperationsDelegate?
    
    init(powerAuth: PowerAuthSDK, config: WMTConfig, pollingOptions: WMTOperationsPollingOptions = []) {
        self.powerAuth = powerAuth
        self.networking = WPNNetworkingService(powerAuth: powerAuth, config: config.wpnConfig, serviceName: "WMTOperations")
        self.config = config
        self.pollingOptions = pollingOptions
        
        #if os(iOS)
        if pollingOptions.contains(.pauseWhenOnBackground) {
            notificationObservers.append(NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { [weak self] _ in
                guard let `self` = self else {
                    return
                }
                self.pollingLock.synchronized {
                    if self.isPollingOperationsInternal {
                        self.pollingTimer?.invalidate()
                    }
                }
            })
            notificationObservers.append(NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
                guard let `self` = self else {
                    return
                }
                self.pollingLock.synchronized {
                    if self.isPollingPaused {
                        guard let timer = self.pollingTimer else {
                            D.error("This is a logical error, timer shouldn't be deallocated when paused")
                            return
                        }
                        self.pollingTimer = nil
                        self.startPollingOperationsInternal(interval: timer.timeInterval, delayStart: false)
                    }
                }
            })
        }
        #endif
    }
    
    deinit {
        notificationObservers.forEach(NotificationCenter.default.removeObserver)
    }
    
    // MARK: - service API
    
    /// Refreshes operations, but does not return any result. For the result, you can
    /// add a delegate to `delegates` property.
    /// If operations are already loading, the function does nothing.
    func refreshOperations() {
        DispatchQueue.main.async {
            // no need to start new operation loading if there is already one in progress
            if self.isLoadingOperations == false {
                self.getOperations { _ in }
            }
        }
    }
    
    /// Retrieves user operations and calls task when finished.
    ///
    /// - Parameter completion: To be called when operations are loaded.
    ///                         This completion is always called on the main thread.
    /// - Returns: Control object in case the operations needs to be canceled.
    ///
    /// Note: be sure to call this method on the main thread!
    @discardableResult
    func getOperations(completion: @escaping GetOperationsCompletion) -> Cancellable {
        
        // getOperations should always be called from main thread to ensure
        // order of operations
        assert(Thread.isMainThread)
        
        let task = GetOperationsTask(completion: completion)
        
        // register block
       self.tasks.append(task)
        
        // if there is loading in progress, just exit and wait for result
        if isLoadingOperations == false {
        
            isLoadingOperations = true
            
            fetchOps { result in
                // this callback should be called from main thread to prevent inconsistent state when multiple
                // getOperations are called
                assert(Thread.isMainThread)
                // call all registered blocks and clear them
                self.tasks.filter({ $0.isCanceled == false }).forEach { $0.finish(result) }
                self.tasks.removeAll()
                // reset the state
                self.isLoadingOperations = false
            }
        }
        
        return task
    }
    
    /// Retrieves the history of user operations with its current status.
    /// - Parameters:
    ///   - authentication: Authentication object for signing.
    ///   - completion: Result completion.
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    func getHistory(authentication: PowerAuthAuthentication, completion: @escaping (Result<[WMTOperationHistoryEntry], WMTError>) -> Void) -> Operation? {
        
        if !powerAuth.hasValidActivation() {
            DispatchQueue.main.async {
                completion(.failure(WMTError(reason: .missingActivation)))
            }
            return nil
        }
        
        return networking.post(data: .init(), signedWith: authentication, to: WMTOperationEndpoints.History.endpoint) { response, error in
            DispatchQueue.main.async {
                if let result = response?.responseObject {
                    completion(.success(result))
                } else {
                    completion(.failure(error ?? WMTError(reason: .unknown)))
                }
            }
        }
    }
    
    /// Authorize operation with given PowerAuth authentication object.
    ///
    /// - Parameters:
    ///   - operation: Operation that should  be authorized.
    ///   - authentication: Authentication object for signing.
    ///   - completion: Result callback (nil on success).
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    func authorize(operation: WMTOperation, authentication: PowerAuthAuthentication, completion: @escaping(WMTError?) -> Void) -> Operation? {
        
        guard powerAuth.hasValidActivation() else {
            DispatchQueue.main.async {
                completion(WMTError(reason: .missingActivation))
            }
            return nil
        }
        
        let data = WMTAuthorizationData(operationId: operation.id, operationData: operation.data)
        
        return networking.post(data: .init(data), signedWith: authentication, to: WMTOperationEndpoints.Authorize.endpoint) { _, error in
            assert(Thread.isMainThread)
            if error == nil {
                self.operationsRegister.remove(operation: operation)
            }
            completion(self.adjustOperationError(error, auth: true))
            
        }
    }
    
    /// Reject operation with a reason.
    ///
    /// - Parameters:
    ///   - operation: Operation that should be rejected.
    ///   - reason: Reason for the rejection.
    ///   - completion: Result callback (nil on success).
    ///                 This completion is always called on the main thread.
    /// - Returns: Operation object for its state observation.
    func reject(operation: WMTOperation, reason: WMTRejectionReason, completion: @escaping(WMTError?) -> Void) -> Operation? {
        
        guard powerAuth.hasValidActivation() else {
            DispatchQueue.main.async {
                completion(WMTError(reason: .missingActivation))
            }
            return nil
        }
        
        let auth = PowerAuthAuthentication()
        auth.usePossession = true
        
        return networking.post(data: .init(.init(operationId: operation.id, reason: reason)), signedWith: auth, to: WMTOperationEndpoints.Reject.endpoint) { _, error in
            if error == nil {
                self.operationsRegister.remove(operation: operation)
            }
            completion(self.adjustOperationError(error, auth: false))
        }
    }
    
    /// Will sign the given QR operation with authentication object.
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
        
        let op = WPNAsyncBlockOperation { _, markFinished in
            do {
                let uriId  = qrOperation.uriIdForOfflineSigning
                let body   = qrOperation.dataForOfflineSigning
                let nonce  = qrOperation.nonceForOfflineSigning
                let signature = try self.powerAuth.offlineSignature(with: authentication, uriId: uriId, body: body, nonce: nonce)
                markFinished {
                    completion(.success(signature))
                }

            } catch let error {
                markFinished {
                    completion(.failure(WMTError(reason: .operations_QROperationFailed, error: error)))
                }
            }
        }
        op.completionQueue = .main
        qrQueue.addOperation(op)
        return op
    }
    
    /// Start operations polling
    func startPollingOperations(interval: TimeInterval, delayStart: Bool) {
        pollingLock.synchronized {
            self.startPollingOperationsInternal(interval: interval, delayStart: delayStart)
        }
    }
    
    private func startPollingOperationsInternal(interval: TimeInterval, delayStart: Bool) {
        guard isPollingPaused == false else {
            D.warning("Polling is paused")
            return
        }
        guard pollingTimer == nil else {
            D.warning("Polling already in progress")
            return
        }
        
        // When user doesn't want to wait for the first result, just refresh the operations
        // outside of the timer. This may lead to the first "timed call" earlier than the interval, but it's
        // acceptable for the sake of the simpler implementation.
        if delayStart == false {
            refreshOperations()
        }
        
        D.print("Operations polling started with \(interval) seconds interval")
        pollingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refreshOperations()
        }
    }
    
    /// Stops operations polling
    func stopPollingOperations() {
        pollingLock.synchronized {
            self.stopPollingOperationsInternal()
        }
    }
    
    private func stopPollingOperationsInternal() {
        guard let timer = pollingTimer else {
            return
        }
        pollingTimer = nil
        timer.invalidate()
        D.print("Operations polling stopped")
    }
    
    // MARK: - private functions
    
    private func fetchAvailableOperations(completion: @escaping ([WMTUserOperation]?, WMTError?) -> Void) {
        
        if !powerAuth.hasValidActivation() {
            completion(nil, WMTError(reason: .missingActivation))
            return
        }
        
        let auth = PowerAuthAuthentication()
        auth.usePossession = true
        
        networking.post(data: .init(), signedWith: auth, to: WMTOperationEndpoints.List.endpoint) { response, error in
            completion(response?.responseObject, error)
        }
    }
    
    private func shouldContinueLoading() -> Bool {
        assert(Thread.isMainThread) // main thread to sync this method with getOperations calls
        return tasks.contains { $0.isCanceled == false }
    }
    
    private func fetchOps(completion: @escaping GetOperationsCompletion) {
        
        fetchAvailableOperations { ops, error in
                
            guard self.shouldContinueLoading() else {
                self.processFetchResult(nil, nil, completion)
                return
            }
            
            self.processFetchResult(ops, error, completion)
        }
    }
    
    private func processFetchResult(_ operations: [WMTUserOperation]?, _ error: WMTError?, _ completion: GetOperationsCompletion) {
        
        if let ops = operations {
            lastFetchResult = .success(ops)
            operationsRegister.replace(with: ops)
        } else {
            let err = error ?? WMTError(reason: .unknown)
            lastFetchResult = .failure(err)
            delegate?.operationsFailed(error: err)
        }
        
        completion(lastFetchResult!)
    }
    
    /// If request for operation fails at known error code, then this private function adjusts description of given AuthError.
    /// The provided string is then typically presented into the UI.
    private func adjustOperationError(_ error: WMTError?, auth: Bool) -> WMTError? {
        
        guard let error = error else {
            return nil
        }

        var reason: WMTErrorReason?

        if let errorCode = error.restApiError?.errorCode {
            switch errorCode {
            case .invalidActivation:
                reason = .operations_invalidActivation
            case .operationAlreadyFailed:
                reason = .operations_alreadyFailed
            case .operationAlreadyFinished:
                reason = .operations_alreadyFinished
            case .operationAlreadyCancelled:
                reason = .operations_alreadyCanceled
            case .operationExpired:
                if auth {
                    reason = .operations_authExpired
                } else {
                    reason = .operations_rejectExpired
                }
            default:
                break
            }
        }
        if let reason = reason {
            return .wrap(reason, error)
        }
        
        return error
    }
}

private class OperationsRegister {
    
    /// List of currently available operations
    private(set) var currentOperations = [WMTUserOperation]()
    
    /// A set of operation identifiers.
    private var currentOperationsSet = Set<String>()
    
    /// Returns true if register is empty
    var isEmpty: Bool {
        return self.currentOperations.isEmpty
    }
    
    typealias OnChangeCallback = (_ operations: [WMTUserOperation], _ added: [WMTUserOperation], _ removed: [WMTUserOperation]) -> Void
    /// Callback  that is called everytime that register changed
    private let onChangeCallback: OnChangeCallback
    
    init(callback: @escaping OnChangeCallback) {
        onChangeCallback = callback
    }
    
    /// Adds a multiple operations to the register.
    /// Returns list of added and removed operations.
    @discardableResult
    func replace(with operations: [WMTUserOperation]) -> (added: [WMTUserOperation], removed: [WMTUserOperation]) {
        assert(Thread.isMainThread)
        // Process received list of operations to build an array of added objects
        var addedOperations = [WMTUserOperation]()
        var addedOperationsSet = Set<String>()
        for newOp in operations {
            if !self.currentOperationsSet.contains(newOp.id) {
                // identifier is not in current set
                addedOperations.append(newOp)
                addedOperationsSet.insert(newOp.id)
            }
        }
        // Build a list of removed operations
        let newOperationsSet = Set<String>(operations.map { $0.id })
        var removedOperations = [WMTUserOperation]()
        for op in self.currentOperations {
            if !newOperationsSet.contains(op.id) {
                removedOperations.append(op)
            }
        }
        
        // Now remove no longer valid operations
        for removedOp in removedOperations {
            if let index = self.currentOperations.firstIndex(where: { $0.id == removedOp.id }) {
                self.currentOperations.remove(at: index)
                self.currentOperationsSet.remove(removedOp.id)
            }
        }
        // ...and append new objects
        self.currentOperations.append(contentsOf: addedOperations)
        self.currentOperationsSet.formUnion(addedOperationsSet)
        
        // we need to call onChanged even if nothing changed, because the objects are replaced by different insntances
        onChangeCallback(currentOperations, addedOperations, removedOperations)
        // Returns list of operations
        return (addedOperations, removedOperations)
    }
    
    /// Removes an operation from register
    func remove(operation: WMTOperation) {
        assert(Thread.isMainThread)
        if let index = self.currentOperationsSet.firstIndex(of: operation.id) {
            currentOperationsSet.remove(at: index)
        }
        if let index = self.currentOperations.firstIndex(where: { $0.id == operation.id }) {
            let removedOperation = currentOperations.remove(at: index)
            onChangeCallback(currentOperations, [], [removedOperation])
        }
    }
}

/// Class that wraps completion block that will be finished with the result of `getOperation` call
///
/// Note that the given completion will be always executed on the **main thread**.
private class GetOperationsTask: Cancellable {
    
    fileprivate var isCanceled = false
    private var completion: GetOperationsCompletion
    
    init(completion: @escaping GetOperationsCompletion) {
        self.completion = completion
    }
    
    func cancel() {
        isCanceled = true
    }
    
    /// Function that synchronously finishes the task on Main Queue.
    /// We assume that all operations will be rendered and processed on main queue anyway.
    fileprivate func finish(_ result: GetOperationsResult) {
        
        guard isCanceled == false else {
            return
        }
        
        completion(result)
    }
}

public extension Result where Success == [WMTUserOperation], Failure == WMTError {
    /// Operations in the result. In case of error, empty array is returned
    var operations: [WMTUserOperation] {
        switch self {
        case .success(let operations): return operations
        case .failure: return []
        }
    }
}
