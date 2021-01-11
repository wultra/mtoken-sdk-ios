//
// Copyright 2021 Wultra s.r.o.
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

// MARK: - Public protocols used by the watcher

/// Protocol defining an operation for the WMTOperationExpirationWatcher.
public protocol WMTExpirableOperation {
    /// When the operation expires
    var operationExpires: Date { get }
    
    /// Comparing method
    /// - Parameter other: The other operation to check against
    ///
    /// Default implementation is provided in the end of this file as
    /// an extension.
    func equals(other: WMTExpirableOperation) -> Bool
}

/// Provides current date. Can be a system date, server date or whatever
/// you choose. Default implementation of this protocol returns system date.
public protocol WMTCurrentDateProvider {
    var currentDate: Date { get }
}

/// Protocol for delegate which gets called when operation expires
public protocol WMTOperationExpirationWatcherDelegate: class {
    
    /// Called when operation(s) expire(s).
    /// The method is called on the main thread by the `WMTOperationExpirationWatcher`.
    /// - Parameter expiredOperations: array of operations that expired
    func operationsExpired(_ expiredOperations: [WMTExpirableOperation])
}

// MARK: - The main class

/// Expiration Watcher is a utility class that can notify you when an operation expires.
/// In the happy scenario when the operation expires, a notification is sent to the phone.
/// In some cases this might fail (as push messages are not guaranteed to be delivered) and then
/// it comes very handy to be notified internally and act upon it.
///
/// The default behavior of the expiration is based on the system date and time (by using `Date()`).
/// So if the user chooses to change it, it might not work. If you have for example your server time, you can provide
/// it via `currentDateProvider` property.
///
/// Since expiration checking is implemented in the best-effort way, the primary way
/// of operation expiration verification is reloading the operation from the server.
///
/// To prevent spamming of the utility by the wrong configuration of the time or desynchronization of the
/// server and the client, minimum report time between 2 reports is 5 seconds.
public class WMTOperationExpirationWatcher {
    
    // MARK: - Public properties
    
    /// Provider of the current date and time provider. Default implementation returns new `Date()` instance.
    public var currentDateProvider: WMTCurrentDateProvider = WMTOffsetDateProvider()
    /// Delegate that will be notified about the expiration.
    public weak var delegate: WMTOperationExpirationWatcherDelegate?
    
    // MARK: - Private properties
    
    private var operationsToWatch = [WMTExpirableOperation]() // source of "truth" of what is being watched
    private var timer: Timer? // timer for scheduling
    private let lock = WMTLock()
    
    // MARK: - Public interface
    
    /// Creates the instance of the watcher
    public init() {
        
    }
    
    /// Asynchronously provides currently watched operations.
    /// - Parameter callback: callback with watched operations (called on the **main thread**)
    public func getWatchedOperations(callback: @escaping (([WMTExpirableOperation]) -> ())) {
        lock.synchronized {
            let ops = self.operationsToWatch
            DispatchQueue.main.async {
                callback(ops)
            }
        }
    }
    
    /// Add operation for watching (asynchronously).
    /// - Parameter operation: Operation to watch
    /// - Parameter completion: Called when finished (on main thread). The parameter is the currently watched operation.
    public func add(_ operation: WMTExpirableOperation, completion: (([WMTExpirableOperation]) -> ())? = nil) {
        add([operation], completion: completion)
    }
    
    /// Add operations for watching (asynchronously).
    /// - Parameter operations: Operations to watch
    /// - Parameter completion: Called when finished (on main thread). The parameter is the currently watched operation.
    public func add(_ operations: [WMTExpirableOperation], completion: (([WMTExpirableOperation]) -> ())? = nil) {
        
        let currentDate = currentDateProvider.currentDate
        for op in operations {
            // we do not remove expired operations.
            // Operation can expire during the networking communication. Such operation
            // would be lost and never reported as expired.
            if op.isExpired(currentDate) {
                D.warning("WMTOperationExpirationWatcher: You're adding an expired operation to watch.")
            }
        }
        
        lock.synchronized { [weak self] in
            
            defer {
                DispatchQueue.main.async {
                    completion?(self?.operationsToWatch ?? [])
                }
            }
            
            guard operations.isEmpty == false else {
                D.warning("WMTOperationExpirationWatcher: Cannot watch empty array of operations")
                return
            }
            
            guard let self = self else {
                return
            }
            
            var opsToWatch = [WMTExpirableOperation]()
            for op in operations {
                // filter already added operations
                if self.operationsToWatch.contains(where: { $0.equals(other: op)} ) {
                    D.warning("WMTOperationExpirationWatcher: Operation cannot be watched - already there.")
                } else {
                    opsToWatch.append(op)
                }
            }
            
            if opsToWatch.isEmpty {
                D.warning("WMTOperationExpirationWatcher: All operations are already watched")
            } else {
                D.print("WMTOperationExpirationWatcher: Adding \(opsToWatch.count) operation to watch.")
                self.operationsToWatch.append(contentsOf: opsToWatch)
                self.prepareTimer()
            }
        }
    }
    
    /// Stop watching operations for expiration.
    /// - Parameter operations: operations to watch
    /// - Parameter completion: Called when finished (on main thread). The parameter is the currently watched operation.
    public func remove(_ operations: [WMTExpirableOperation], completion: (([WMTExpirableOperation]) -> ())? = nil) {
        stop(operations, completion: completion)
    }
    
    /// Stop watching an operation for expiration.
    /// - Parameter operation: operation to watch
    /// - Parameter completion: Called when finished (on main thread). The parameter is the currently watched operation.
    public func remove(_ operation: WMTExpirableOperation, completion: (([WMTExpirableOperation]) -> ())? = nil) {
        stop([operation], completion: completion)
    }
    
    /// Stop watching all operation
    /// - Parameter completion: Called when finished (on main thread). The parameter is the currently watched operation.
    public func removeAll(completion: (([WMTExpirableOperation]) -> ())? = nil) {
        stop(nil, completion: completion)
    }
    
    // MARK: - Private methods
    
    private func stop(_ operations: [WMTExpirableOperation]?, completion: (([WMTExpirableOperation]) -> ())? = nil) {
        lock.synchronized { [weak self] in
            defer {
                completion?(self?.operationsToWatch ?? [])
            }
            // is there anything to stop?
            guard self?.operationsToWatch.isEmpty == false else {
                return
            }
            // when nil is provided, we consider it as "stop all"
            if let operations = operations {
                self?.operationsToWatch.removeAll(where: { current in operations.contains(where: { toRemove in toRemove.equals(other: current) }) })
                D.print("WMTOperationExpirationWatcher: Stoped watching \(operations.count) operations.")
            } else {
                self?.operationsToWatch.removeAll()
                D.print("WMTOperationExpirationWatcher: Stoped watching all operations.")
            }
            self?.prepareTimer()
        }
    }
    
    private func prepareTimer() {
        
        // stop the previous timer
        timer?.invalidate()
        timer = nil
        
        guard operationsToWatch.isEmpty == false else {
            D.print("WMTOperationExpirationWatcher: No operations to watch.")
            return
        }
        
        guard let firstOp = operationsToWatch.sorted(by: { $0.operationExpires < $1.operationExpires }).first else {
            // this should never happened!
            return
        }
        
        // This is a precaution when you'll receive an expired operation from the backend over and over again
        // and it would lead to infinite refresh time. This also helps when device and backend time is out of sync heavily.
        // This leads to a minimal "expire report time" of 5 seconds.
        let interval = max(5, firstOp.operationExpires.timeIntervalSince1970 - currentDateProvider.currentDate.timeIntervalSince1970)
        
        D.print("WMTOperationExpirationWatcher: Scheduling operation expire check in \(Int(interval)) seconds.")
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
                
                guard let self = self else {
                    return
                }
                
                self.lock.synchronized {
                    
                    let currentDate = self.currentDateProvider.currentDate
                    let expiredOps = self.operationsToWatch.filter { $0.isExpired(currentDate) }
                    
                    guard expiredOps.isEmpty == false else {
                        return
                    }
                    
                    self.operationsToWatch.removeAll(where: { $0.isExpired(currentDate) })
                    self.prepareTimer()
                    DispatchQueue.main.async {
                        D.print("WMTOperationExpirationWatcher: Reporting \(expiredOps.count) expired operations.")
                        self.delegate?.operationsExpired(expiredOps)
                    }
                }
            }
        }
    }
}

// MARK: - Public utilities

/// Default implementation of a date provider.
/// You can customize this provider by the `TimeInterval` offset that is added to the new `Date()` instance
/// that is returned for `currentDate` property
public class WMTOffsetDateProvider: WMTCurrentDateProvider {
    
    private let offset: TimeInterval
    
    public init(offset: TimeInterval = 0) {
        self.offset = offset
    }
    
    public var currentDate: Date { return Date().addingTimeInterval(offset) }
}

/// Conformation to `WMTExpirableOperation` for default object returned
extension WMTUserOperation: WMTExpirableOperation {
    
}

/// Default implementation of the `equals` method of the `WMTExpirableOperation` protocol for classes.
extension WMTExpirableOperation where Self: AnyObject {
    public func equals(other: WMTExpirableOperation) -> Bool {
        if let this = self as? WMTOperation, let that = other as? WMTOperation {
            return this.id == that.id && this.data == that.data && self.operationExpires == other.operationExpires
        } else {
            D.warning("WMTExpirableOperation: Fallbacked to comparing `WMTExpirableOperation`s by reference.")
            return self === (other as AnyObject)
        }
        
    }
}

// MARK: - Private utilities

private extension WMTExpirableOperation {
    func isExpired(_ currentDate: Date = Date()) -> Bool {
        return operationExpires.timeIntervalSince1970 - currentDate.timeIntervalSince1970 < 0
    }
}
