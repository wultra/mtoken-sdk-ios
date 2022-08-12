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
    ///   - networkingConfig: Networking service config
    ///   - pollingOptions: Polling feature configuration
    /// - Returns: Operations service
    func createWMTOperations(networkingConfig: WPNConfig, pollingOptions: WMTOperationsPollingOptions = []) -> WMTOperations {
        return WMTOperationsImpl(networking: WPNNetworkingService(powerAuth: self, config: networkingConfig, serviceName: "WMTOperations"), pollingOptions: pollingOptions)
    }
}

public extension WPNNetworkingService {
    
    /// Creates instance of the `WMTOperations` on top of the WPNNetworkingService/PowerAuth instance.
    /// - Parameters:
    ///   - pollingOptions: Polling feature configuration
    /// - Returns: Operations service
    func createWMTOperations(pollingOptions: WMTOperationsPollingOptions = []) -> WMTOperations {
        return WMTOperationsImpl(networking: self, pollingOptions: pollingOptions)
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
    private lazy var powerAuth = networking.powerAuth
    private let networking: WPNNetworkingService
    private let qrQueue: OperationQueue = {
        let q = OperationQueue()
        q.name = "WMTOperationsQRQueue"
        return q
    }()
    
    /// If operation loading is currently in progress
    private(set) var isLoadingOperations = false {
        didSet {
            let val = isLoadingOperations
            delegate?.operationsLoading(loading: val)
        }
    }
    
    var isPollingOperations: Bool { return pollingLock.synchronized { isPollingOperationsInternal } }
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
    
    init(networking: WPNNetworkingService, pollingOptions: WMTOperationsPollingOptions = []) {
        self.networking = networking
        self.pollingOptions = pollingOptions
        
        #if os(iOS)
        if pollingOptions.contains(.pauseWhenOnBackground) {
            notificationObservers.append(NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { [weak self] _ in
                guard let self = self else {
                    return
                }
                self.pollingLock.synchronized {
                    if self.isPollingOperationsInternal {
                        self.pollingTimer?.invalidate()
                    }
                }
            })
            notificationObservers.append(NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
                guard let self = self else {
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
    
    func refreshOperations() {
        DispatchQueue.main.async {
            // no need to start new operation loading if there is already one in progress
            if self.isLoadingOperations == false {
                self.getOperations { _ in }
            }
        }
    }
    
    @discardableResult
    func getOperations(completion: @escaping GetOperationsCompletion) -> Cancellable {
        
        let task = GetOperationsTask(completion: completion)
        
        DispatchQueue.main.async {
        
            // register block
            self.tasks.append(task)
            
            // if there is loading in progress, just exit and wait for result
            if self.isLoadingOperations == false {
            
                self.isLoadingOperations = true
                
                self.fetchOperations { result in
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
        }
        
        return task
    }
    
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
    
    func authorize(operation: WMTOperation, authentication: PowerAuthAuthentication, completion: @escaping(WMTError?) -> Void) -> Operation? {
        return authorize(operation: operation, with: authentication) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    func authorize(operation: WMTOperation, with authentication: PowerAuthAuthentication, completion: @escaping (Result<Void, WMTError>) -> Void) -> Operation? {
        
        guard powerAuth.hasValidActivation() else {
            DispatchQueue.main.async {
                completion(.failure(WMTError(reason: .missingActivation)))
            }
            return nil
        }
        
        let data = WMTAuthorizationData(operationId: operation.id, operationData: operation.data)
        
        return networking.post(data: .init(data), signedWith: authentication, to: WMTOperationEndpoints.Authorize.endpoint) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(self.adjustOperationError(error, auth: true)))
                } else {
                    self.operationsRegister.remove(operation: operation)
                    completion(.success(()))
                }
            }
        }
    }
    
    func reject(operation: WMTOperation, reason: WMTRejectionReason, completion: @escaping(WMTError?) -> Void) -> Operation? {
        return reject(operation: operation, with: reason) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    func reject(operation: WMTOperation, with reason: WMTRejectionReason, completion: @escaping(Result<Void, WMTError>) -> Void) -> Operation? {
        
        guard powerAuth.hasValidActivation() else {
            DispatchQueue.main.async {
                completion(.failure(WMTError(reason: .missingActivation)))
            }
            return nil
        }
                
        return networking.post(
            data: .init(.init(operationId: operation.id, reason: reason)),
            signedWith: .possession(),
            to: WMTOperationEndpoints.Reject.endpoint
        ) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.operationsRegister.remove(operation: operation)
                    completion(.failure(self.adjustOperationError(error, auth: false)))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func authorize(qrOperation: WMTQROperation, uriId: String, authentication: PowerAuthAuthentication, completion: @escaping(Result<String, WMTError>) -> Void) -> Operation {
        
        let op = WPNAsyncBlockOperation { _, markFinished in
            do {
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
    
    private func fetchOperations(completion: @escaping GetOperationsCompletion) {
        
        if !powerAuth.hasValidActivation() {
            completion(.failure(WMTError(reason: .missingActivation)))
            return
        }
        
        networking.post(data: .init(), signedWith: .possession(), to: WMTOperationEndpoints.List.endpoint) { response, error in
            DispatchQueue.main.async {
                
                // if all tasks were canceled, just ignore the result.
                guard self.tasks.contains(where: { $0.isCanceled == false }) else {
                    completion(.failure(WMTError(reason: .unknown)))
                    return
                }
                
                let result: GetOperationsResult
                
                if let ops = response?.responseObject {
                    result = .success(ops)
                    self.operationsRegister.replace(with: ops)
                } else {
                    let err = error ?? WMTError(reason: .unknown)
                    result = .failure(err)
                    self.delegate?.operationsFailed(error: err)
                }
                
                self.lastFetchResult = result
                completion(result)
            }
        }
    }
    
    /// If request for operation fails at known error code, then this private function adjusts description of given AuthError.
    private func adjustOperationError(_ error: WMTError, auth: Bool) -> WMTError {

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
    var isEmpty: Bool { currentOperations.isEmpty }
    
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
        for newOp in operations where currentOperationsSet.contains(newOp.id) == false {
            // identifier is not in current set
            addedOperations.append(newOp)
            addedOperationsSet.insert(newOp.id)
        }
        // Build a list of removed operations
        let newOperationsSet = Set<String>(operations.map { $0.id })
        var removedOperations = [WMTUserOperation]()
        for op in currentOperations where newOperationsSet.contains(op.id) == false {
            removedOperations.append(op)
        }
        
        // Now remove no longer valid operations
        for removedOp in removedOperations {
            if let index = currentOperations.firstIndex(where: { $0.id == removedOp.id }) {
                currentOperations.remove(at: index)
                currentOperationsSet.remove(removedOp.id)
            }
        }
        // ...and append new objects
        currentOperations.append(contentsOf: addedOperations)
        currentOperationsSet.formUnion(addedOperationsSet)
        
        // we need to call onChanged even if nothing changed, because the objects are replaced by different insntances
        onChangeCallback(currentOperations, addedOperations, removedOperations)
        // Returns list of operations
        return (addedOperations, removedOperations)
    }
    
    /// Removes an operation from register
    func remove(operation: WMTOperation) {
        assert(Thread.isMainThread)
        if let index = currentOperationsSet.firstIndex(of: operation.id) {
            currentOperationsSet.remove(at: index)
        }
        if let index = currentOperations.firstIndex(where: { $0.id == operation.id }) {
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
