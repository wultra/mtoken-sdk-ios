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

import XCTest
import WultraMobileTokenSDK

class OperationExpirationTests: XCTestCase {
    
    private let watcher = WMTOperationExpirationWatcher()
    private var delegate: WatcherDelegate? {
        didSet {
            watcher.delegate = delegate
        }
    }
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        delegate = nil
        watcher.removeAll()
    }
    
    func testAddOperation() {
        let op = Operation()
        watcher.add(op)
        let ops = watcher.getWatchedOperations()
        XCTAssert(ops.count == 1 && ops.first!.equals(other: op))
    }
    
    func testAddSameOperationTwice() {
        let op = Operation()
        watcher.add(op)
        let ops = watcher.add(op)
        XCTAssert(ops.count == 1 && ops.first!.equals(other: op))
    }
    
    func testAddOperations() {
        let ops = watcher.add([Operation(), Operation()])
        XCTAssert(ops.count == 2)
    }
    
    func testRemoveOperation() {
        let op = Operation()
        let ops = watcher.add(op)
        XCTAssert(ops.count == 1 && ops.first!.equals(other: op))
        let opsAfterRemoved = watcher.remove(op)
        XCTAssert(opsAfterRemoved.isEmpty)
    }
    
    func testRemoveNonAddedOperation() {
        let op = Operation()
        let ops = watcher.add(op)
        XCTAssert(ops.count == 1 && ops.first!.equals(other: op))
        let opsAfterRemoved = watcher.remove(Operation())
        XCTAssert(opsAfterRemoved.count == 1)
    }
    
    func testRemoveOperations() {
        let op = Operation()
        let op2 = Operation()
        watcher.add(op)
        let ops = watcher.add(op2)
        XCTAssert(ops.count == 2)
        let opsAfterRemoved = watcher.remove([op, op2])
        XCTAssert(opsAfterRemoved.isEmpty)
    }
    
    func testRemoveAllOperations() {
        watcher.add(Operation())
        let ops = watcher.add([Operation(), Operation()])
        XCTAssert(ops.count == 3)
        let opsAfterRemoved = watcher.removeAll()
        XCTAssert(opsAfterRemoved.isEmpty)
    }
    
    func testExpiring() {
        let exp = expectation(description: "Operation will expire")
        let op = Operation()
        delegate = WatcherDelegate { ops in
            XCTAssert(ops.count == 1 && ops.first!.equals(other: op))
            let curOps = self.watcher.getWatchedOperations()
            XCTAssert(curOps.isEmpty)
            exp.fulfill()
        }
        watcher.add(op)
        // we need to wait longer, because minimum report time is 5 seconds
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testExpiring2() {
        let exp = expectation(description: "Operation will expire")
        delegate = WatcherDelegate { ops in
            XCTAssert(ops.count == 1)
            let curOps = self.watcher.getWatchedOperations()
            XCTAssert(curOps.count == 1)
            exp.fulfill()
        }
        watcher.add([Operation(), Operation(Date().addingTimeInterval(20))])
        // we need to wait longer, because minimum report time is 5 seconds
        waitForExpectations(timeout: 10, handler: nil)
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
