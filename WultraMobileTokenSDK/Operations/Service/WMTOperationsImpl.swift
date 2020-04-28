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

public extension PowerAuthSDK {
    func createWMTOperations(config: WMTConfig) -> WMTOperations {
        return WMTOperationsImpl(powerAuth: self, config: config)
    }
}

public extension WMTErrorReason {
    /// Request needs valid powerauth activation
    static let operations_invalidActivation = WMTErrorReason(rawValue: "operations_invalidActivation")
    /// Operation is already in failed state
    static let operations_alreadyFailed = WMTErrorReason(rawValue: "operations_alreadyFailed")
    /// Operation is already in finished state
    static let operations_alreadyFinished = WMTErrorReason(rawValue: "operations_alreadyFinished")
    /// Operation is already in canceled state
    static let operations_alreadyCanceled = WMTErrorReason(rawValue: "operations_alreadyCanceled")
    /// Operation expired.
    static let operations_alreadyRejected = WMTErrorReason(rawValue: "operations_expired")
    /// Operation has expired when trying to approve the operation
    static let operations_authExpired = WMTErrorReason(rawValue: "operations_authExpired")
    /// Operation has expired when trying to reject the operation
    static let operations_rejectExpired = WMTErrorReason(rawValue: "operations_rejectExpired")
    
    /// Couldn't sign QR operation
    static let operations_QROperationFailed = WMTErrorReason(rawValue: "operations_QRFailed")
}

class WMTOperationsImpl: WMTOperations {
    
    // Dependencies
    private let powerAuth: PowerAuthSDK
    private let networking: WMTNetworkingService
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
    
    var isPollingOperations: Bool { return pollingTimer != nil }
    
    private var tasks = [GetOperationsTask]() // Task that are waiting for operation fetch
    private var pollingTimer: Timer? // Timer that manages operations polling when requested
    
    /// Operation register holds operations in order
    private lazy var operationsRegister = OperationsRegister { [weak self] ops, added, removed in
        self?.delegate?.operationsChanged(operations: ops, removed: removed, added: added)
    }
    
    /// Last result of operation fetch.
    private(set) var lastFetchResult: GetOperationsResult?
    
    /// Delegate is being reported about operations loading state
    weak var delegate: WMTOperationsDelegate?
    
    init(powerAuth: PowerAuthSDK, config: WMTConfig) {
        self.powerAuth = powerAuth
        self.networking = WMTNetworkingService(powerAuth: powerAuth, config: config, serviceName: "WMTOperations")
        self.config = config
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
    
    /// Retrieves user operations and calls task when finished
    ///
    /// - Parameter completion: to be called when operations are loaded
    ///
    /// Note: be sure to call this method on Main Thread!
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
    
    /// Authorize operation with given PowerAuth authentication object.
    ///
    /// - Parameters:
    ///   - operation: operation that should  be authorized
    ///   - authentication: authentication object for signing
    ///   - completion: result callback (nil on success)
    func authorize(operation: WMTUserOperation, authentication: PowerAuthAuthentication, completion: @escaping(WMTError?)->Void) -> Operation? {
        
        guard powerAuth.hasValidActivation() else {
            completion(WMTError(reason: .missingActivation))
            return nil
        }
        
        let url         = config.buildURL(WMTOperationEndpoints.AuthorizeOperation.url)
        let uriId       = WMTOperationEndpoints.AuthorizeOperation.uriId
        let requestData = WMTOperationEndpoints.AuthorizeOperation.RequestData(WMTAuthorizationData(operationId: operation.id, operationData: operation.data))
        let request     = WMTOperationEndpoints.AuthorizeOperation.Request(url, uriId: uriId, auth: authentication, requestData: requestData)
        
        return networking.post(request, completion: { response, error in
            if error == nil {
                self.operationsRegister.remove(operation: operation)
            }
            completion(self.adjustOperationError(error, auth: true))
        })
    }
    
    /// Reject operation with a reason.
    ///
    /// - Parameters:
    ///   - operation: operation that should be rejected
    ///   - reason: reason  for rejection
    ///   - completion: result callback (nil on success)
    func reject(operation: WMTUserOperation, reason: WMTRejectionReason, completion: @escaping(WMTError?)->Void) -> Operation? {
        
        guard powerAuth.hasValidActivation() else {
            completion(WMTError(reason: .missingActivation))
            return nil
        }
        
        let auth = PowerAuthAuthentication()
        auth.usePossession = true
        
        let url         = config.buildURL(WMTOperationEndpoints.RejectOperation.url)
        let uriId       = WMTOperationEndpoints.RejectOperation.uriId
        let requestData = WMTOperationEndpoints.RejectOperation.RequestData(WMTRejectionData(operationId: operation.id, reason: reason))
        let request     = WMTOperationEndpoints.RejectOperation.Request(url, uriId: uriId, auth: auth, requestData: requestData)
        
        return networking.post(request) { (response, error) in
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
    ///   - authentication: authentication object for signing
    ///   - completion: result completion
    /// - Returns: operation for state observation
    func authorize(qrOperation: WMTQROperation, authentication: PowerAuthAuthentication, completion: @escaping (Result<String, WMTError>) -> Void) -> Operation {
        
        let op = BlockOperation {
            do {
                let uriId  = qrOperation.uriIdForOfflineSigning
                let body   = qrOperation.dataForOfflineSigning
                let nonce  = qrOperation.nonceForOfflineSigning
                let signature = try self.powerAuth.offlineSignature(with: authentication, uriId: uriId, body: body, nonce: nonce)
                completion(.success(signature))
                //self.stats.record(event: .offline_generated)

            } catch let error {
                completion(.failure(WMTError(reason: .operations_QROperationFailed, error: error)))
            }
        }
        qrQueue.addOperation(op)
        return op
    }
    
    /// Start operations polling
    func startPollingOperations(interval: TimeInterval) {
        guard pollingTimer == nil else {
            D.warning("Polling already in progress")
            return
        }
        
        D.print("Operations polling started with \(interval) seconds interval")
        pollingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refreshOperations()
        }
    }
    
    /// Stops operations polling
    func stopPollingOperations() {
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
        
        let url         = config.buildURL(WMTOperationEndpoints.GetOperations.url)
        let tokenName   = WMTOperationEndpoints.GetOperations.tokenName
        let requestData = WMTOperationEndpoints.GetOperations.RequestData()
        let request     = WMTOperationEndpoints.GetOperations.Request(url, tokenName: tokenName, auth: auth, requestData:requestData)
        
        networking.post(request, completion: { (response, error) in
            completion(response?.responseObject, error)
        })
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

fileprivate class OperationsRegister {
    
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
    func remove(operation: WMTUserOperation) {
        if let index = self.currentOperationsSet.firstIndex(of: operation.id) {
            self.currentOperationsSet.remove(at: index)
        }
        if let index = self.currentOperations.firstIndex(where: { $0.id == operation.id }) {
            self.currentOperations.remove(at: index)
            onChangeCallback(currentOperations, [], [operation])
        }
    }
}

/// Class that wraps completion block that will be finished with the result of `getOperation` call
///
/// Note that the given completion will be always executed on the **main thread**.
fileprivate class GetOperationsTask: Cancellable {
    
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
