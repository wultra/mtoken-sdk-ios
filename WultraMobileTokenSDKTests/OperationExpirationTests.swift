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
import Testing
import WultraMobileTokenSDK

final class OperationExpirationTests {
    
    private let watcher = WMTOperationExpirationWatcher()
    private var delegate: WatcherDelegate? {
        didSet {
            watcher.delegate = delegate
        }
    }
    
    deinit {
        delegate = nil
        watcher.removeAll()
    }
    
    @Test
    func testAddOperation() {
        let op = Operation()
        watcher.add(op)
        let ops = watcher.getWatchedOperations()
        #expect(ops.count == 1 && ops.first!.equals(other: op))
    }
    
    @Test
    func testAddSameOperationTwice() {
        let op = Operation()
        watcher.add(op)
        let ops = watcher.add(op)
        #expect(ops.count == 1 && ops.first!.equals(other: op))
    }
    
    @Test
    func testAddOperations() {
        let ops = watcher.add([Operation(), Operation()])
        #expect(ops.count == 2)
    }
    
    @Test
    func testRemoveOperation() {
        let op = Operation()
        let ops = watcher.add(op)
        #expect(ops.count == 1 && ops.first!.equals(other: op))
        let opsAfterRemoved = watcher.remove(op)
        #expect(opsAfterRemoved.isEmpty)
    }
    
    @Test
    func testRemoveNonAddedOperation() {
        let op = Operation()
        let ops = watcher.add(op)
        #expect(ops.count == 1 && ops.first!.equals(other: op))
        let opsAfterRemoved = watcher.remove(Operation())
        #expect(opsAfterRemoved.count == 1)
    }
    
    @Test
    func testRemoveOperations() {
        let op = Operation()
        let op2 = Operation()
        watcher.add(op)
        let ops = watcher.add(op2)
        #expect(ops.count == 2)
        let opsAfterRemoved = watcher.remove([op, op2])
        #expect(opsAfterRemoved.isEmpty)
    }
    
    @Test
    func testRemoveAllOperations() {
        watcher.add(Operation())
        let ops = watcher.add([Operation(), Operation()])
        #expect(ops.count == 3)
        let opsAfterRemoved = watcher.removeAll()
        #expect(opsAfterRemoved.isEmpty)
    }
    
    @Test
    func testExpiring() async throws {
        let signal = AsyncTestSignal()
        let op = Operation()
        delegate = WatcherDelegate { ops in
            #expect(ops.count == 1 && ops.first!.equals(other: op))
            let curOps = self.watcher.getWatchedOperations()
            #expect(curOps.isEmpty)
            Task { await signal.fulfill() }
        }
        watcher.add(op)
        // we need to wait longer, because minimum report time is 5 seconds
        try await wait(for: signal, timeout: 10)
    }
    
    @Test
    func testExpiring2() async throws {
        let signal = AsyncTestSignal()
        delegate = WatcherDelegate { ops in
            #expect(ops.count == 1)
            let curOps = self.watcher.getWatchedOperations()
            #expect(curOps.count == 1)
            Task { await signal.fulfill() }
        }
        watcher.add([Operation(), Operation(Date().addingTimeInterval(20))])
        // we need to wait longer, because minimum report time is 5 seconds
        try await wait(for: signal, timeout: 10)
    }
}

private class WatcherDelegate: WMTOperationExpirationWatcherDelegate {
    
    private var callback: ([WMTExpirableOperation]) -> ()
    
    init(callback: @escaping ([WMTExpirableOperation]) -> ()) {
        self.callback = callback
    }
    
    func operationsExpired(_ expiredOperations: [WMTExpirableOperation]) {
        callback(expiredOperations)
    }
}

private class Operation: WMTExpirableOperation {
    
    let operationExpires: Date
    
    init(_ date: Date = Date()) {
        operationExpires = date
    }
}
