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
        let exp = expectation(description: "Operation added")
        let op = Operation()
        watcher.add(op)
        watcher.getWatchedOperations { ops in
            XCTAssert(ops.count == 1 && ops.first!.equals(other: op))
            exp.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testAddSameOperationTwice() {
        let exp = expectation(description: "Operation added only once")
        let op = Operation()
        watcher.add(op)
        watcher.add(op) { ops in
            XCTAssert(ops.count == 1 && ops.first!.equals(other: op))
            exp.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testAddOperations() {
        let exp = expectation(description: "Add operations")
        watcher.add([Operation(), Operation()]) { ops in
            XCTAssert(ops.count == 2)
            exp.fulfill()
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testRemoveOperation() {
        let exp = expectation(description: "Operation remove")
        let op = Operation()
        watcher.add(op) { ops in
            XCTAssert(ops.count == 1 && ops.first!.equals(other: op))
            self.watcher.remove(op) { opsAfterRemoved in
                XCTAssert(opsAfterRemoved.isEmpty)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testRemoveNonAddedOperation() {
        let exp = expectation(description: "Operation remove non added")
        let op = Operation()
        watcher.add(op) { ops in
            XCTAssert(ops.count == 1 && ops.first!.equals(other: op))
            self.watcher.remove(Operation()) { opsAfterRemoved in
                XCTAssert(opsAfterRemoved.count == 1)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testRemoveOperations() {
        let exp = expectation(description: "Operations remove")
        let op = Operation()
        let op2 = Operation()
        watcher.add(op)
        watcher.add(op2) { ops in
            XCTAssert(ops.count == 2)
            self.watcher.remove([op, op2]) { opsAfterRemoved in
                XCTAssert(opsAfterRemoved.isEmpty)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testRemoveAllOperations() {
        let exp = expectation(description: "Operations remove all")
        watcher.add(Operation())
        watcher.add([Operation(), Operation()]) { ops in
            XCTAssert(ops.count == 3)
            self.watcher.removeAll { opsAfterRemoved in
                XCTAssert(opsAfterRemoved.isEmpty)
                exp.fulfill()
            }
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testExpiring() {
        let exp = expectation(description: "Operation will expire")
        let op = Operation()
        delegate = WatcherDelegate { ops in
            XCTAssert(ops.count == 1 && ops.first!.equals(other: op))
            self.watcher.getWatchedOperations { curOps in
                XCTAssert(curOps.isEmpty)
                exp.fulfill()
            }
        }
        watcher.add(op)
        // we need to wait longer, because minimum report time is 5 seconds
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testExpiring2() {
        let exp = expectation(description: "Operation will expire")
        delegate = WatcherDelegate { ops in
            XCTAssert(ops.count == 1)
            self.watcher.getWatchedOperations { curOps in
                XCTAssert(curOps.count == 1)
                exp.fulfill()
            }
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
