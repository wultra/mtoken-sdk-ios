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

import XCTest
import PowerAuth2
@testable import WultraMobileTokenSDK


/**
 For integration test to be successfully executed, you need to provide
 configuration json file. To more information, visit `WultraMobileTokenSDKTests/Configs/Readme.md`.
 */

class IntegrationTests: XCTestCase {
    
    private var pa: PowerAuthSDK { Self.pa }
    private static var pa: PowerAuthSDK!
    
    private var ops: WMTOperations { Self.ops }
    private static var ops: WMTOperations!
    
    private static let pin = "1234"
    
    override class func setUp() {
        super.setUp()
        
        let exp = XCTestExpectation(description: "setup expectation")
        
        // Integration Utils prepares an valid activation and sets is as primary
        // token activation on nextstep server
        IntegrationUtils.prepareActivation(pin: pin) { instances, err in
            if let instances = instances {
                pa = instances.0
                ops = instances.1
            } else {
                XCTFail(err ?? "Failed to create valid PowerAuth activation.")
            }
            exp.fulfill()
        }
        
        let waiter = XCTWaiter()
        waiter.wait(for: [exp], timeout: 20)
    }
    
    override class func tearDown() {
        super.tearDown()
        let exp = XCTestExpectation(description: "setup expectation")
        
        // after each batch of tests, remove the activation
        let auth = PowerAuthAuthentication()
        auth.usePassword = pin
        auth.usePossession = true
        if let pa = pa {
            pa.removeActivation(with: auth) { err in
                exp.fulfill()
            }
        } else {
            XCTFail("Failed to remove activation")
            exp.fulfill()
        }
        
        let waiter = XCTWaiter()
        waiter.wait(for: [exp], timeout: 20)
    }
    
    /// By default, operation list should be empty
    func testList() {
        let exp = expectation(description: "Empty list of operations")
        
        _ = ops.getOperations { result in
            
            switch result {
            case .success:
                break // nothing to do here
            case .failure(let err):
                XCTFail(err.description)
            }
            exp.fulfill()
            
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }
    
    /// Test of Login operation approval (1FA)
    /// TODO: prepare 1FA op
//    func testApproveLogin() {
//
//        let exp = expectation(description: "Approve login")
//
//        IntegrationUtils.createOperation { error in
//            guard error == nil else {
//                XCTFail(error!)
//                exp.fulfill()
//                return
//            }
//
//            DispatchQueue.main.async {
//                _  = self.ops.getOperations { opResult in
//                    switch opResult {
//                    case .success(let ops):
//                        guard ops.count == 1 else {
//                            XCTFail("1 operation expected. Actual: \(ops.count)")
//                            exp.fulfill()
//                            return
//                        }
//                        let auth = PowerAuthAuthentication()
//                        auth.usePossession = true
//                        self.ops.authorize(operation: ops.first!, authentication: auth) { error in
//                            if let error = error {
//                                XCTFail("Failed to authorize op: \(error.description)")
//                            }
//                            exp.fulfill()
//                        }
//                    case .failure(let error):
//                        XCTFail("Failed to retrieve operations: \(error.description)")
//                        exp.fulfill()
//                    }
//                }
//            }
//        }
//
//        waitForExpectations(timeout: 20, handler: nil)
//    }
    
    // TODO: prepare 1FA op
    /// Test of rejecting login operation (1FA)
//    func testRejectLogin() {
//
//        let exp = expectation(description: "Reject login")
//
//        IntegrationUtils.createOperation { error in
//            guard error == nil else {
//                XCTFail(error!)
//                exp.fulfill()
//                return
//            }
//
//            DispatchQueue.main.async {
//                _  = self.ops.getOperations { opResult in
//                    switch opResult {
//                    case .success(let ops):
//                        guard ops.count == 1 else {
//                            XCTFail("1 operation expected. Actual: \(ops.count)")
//                            exp.fulfill()
//                            return
//                        }
//                        self.ops.reject(operation: ops.first!, reason: .unexpectedOperation) { error in
//                            if let error = error {
//                                XCTFail("Failed to reject op: \(error.description)")
//                            }
//                            exp.fulfill()
//                        }
//                    case .failure(let error):
//                        XCTFail("Failed to retrieve operations: \(error.description)")
//                        exp.fulfill()
//                    }
//                }
//            }
//        }
//
//        waitForExpectations(timeout: 20, handler: nil)
//    }
    
    /// Test of Payment approval (2FA)
    func testApprovePayment() {
        
        let exp = expectation(description: "Approve payment")
        
        IntegrationUtils.createOperation { op in
            guard op != nil else {
                XCTFail("Failed to create operation")
                exp.fulfill()
                return
            }
            
            DispatchQueue.main.async {
                _  = self.ops.getOperations { opResult in
                    switch opResult {
                    case .success(let ops):
                        guard ops.count == 1 else {
                            XCTFail("1 operation expected. Actual: \(ops.count)")
                            exp.fulfill()
                            return
                        }
                        let auth = PowerAuthAuthentication()
                        auth.usePossession = true
                        auth.usePassword = "xxxx" //  wrong password on purpose
                        self.ops.authorize(operation: ops.first!, authentication: auth) { error in
                            if error != nil {
                                let auth = PowerAuthAuthentication()
                                auth.usePossession = true
                                auth.usePassword = Self.pin
                                self.ops.authorize(operation: ops.first!, authentication: auth) { error in
                                    if let error = error {
                                        XCTFail("Failed to authorize op: \(error.description)")
                                    }
                                    exp.fulfill()
                                }
                            } else {
                                XCTFail("Operation approved with wrong password")
                                exp.fulfill()
                            }
                        }
                    case .failure(let error):
                        XCTFail("Failed to retrieve operations: \(error.description)")
                        exp.fulfill()
                    }
                }
            }
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }
    
    /// Test of Payment rejecting (1FA)
    func testRejectPayment() {
        
        let exp = expectation(description: "Reject payment")
        
        IntegrationUtils.createOperation { op in
            guard let op = op else {
                XCTFail("Failed to create operation")
                exp.fulfill()
                return
            }
            
            DispatchQueue.main.async {
                _  = self.ops.getOperations { opResult in
                    switch opResult {
                    case .success(let ops):
                        guard let opToReject = ops.first(where: { $0.id == op.operationId }) else {
                            XCTFail("Operation was not in the oiperation list")
                            exp.fulfill()
                            return
                        }
                        self.ops.reject(operation: opToReject, reason: .unexpectedOperation) { error in
                            if let error = error {
                                XCTFail("Failed to reject op: \(error.description)")
                            }
                            exp.fulfill()
                        }
                    case .failure(let error):
                        XCTFail("Failed to retrieve operations: \(error.description)")
                        exp.fulfill()
                    }
                }
            }
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }
    
    /// Testing that operation polling works.
    func testOperationPolling() {
        let exp = expectation(description: "Polling expectation")
        XCTAssertFalse(ops.isPollingOperations)
        let delegate = OpDelegate { count in
            if count == 4 {
                self.ops.stopPollingOperations()
                exp.fulfill()
            }
        }
        ops.delegate = delegate
        ops.startPollingOperations(interval: 1, delayStart: false)
        XCTAssertTrue(ops.isPollingOperations)

        waitForExpectations(timeout: 20, handler: nil)
        
        XCTAssertFalse(ops.isPollingOperations)
    }
    
    func testHistory() {
        let exp = expectation(description: "history expectation")
        
        // lets create 1 operation and leave it in the state of "pending"
        IntegrationUtils.createOperation { op in
            
            guard let op = op else {
                XCTFail("Failed to create operation")
                exp.fulfill()
                return
            }
            
            let auth = PowerAuthAuthentication()
            auth.usePossession = true
            auth.usePassword = Self.pin
            self.ops.getHistory(authentication: auth) { result in
                switch result {
                case .success(let ops):
                    if let opFromList = ops.first(where: { $0.operation.id == op.operationId }) {
                        XCTAssertEqual(opFromList.status, .pending)
                    } else {
                        XCTFail("Created operation was not in the history")
                    }
                case .failure:
                    XCTFail("History was not retrieved")
                }
                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }
    
    // Testing that operations polling pause works
    func testOperationPollingPause() {
        XCTAssertTrue(ops.pollingOptions.contains(.pauseWhenOnBackground), "Operation service is not set to pause on background")
        let exp = expectation(description: "Timeout expectation")
        XCTAssertFalse(ops.isPollingOperations, "Polling should be inactive")
        let delegate = OpDelegate { count in
            if count == 1 {
                // will resign active should stop polling as the app "is on background"
                NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
            }
        }
        ops.delegate = delegate
        ops.startPollingOperations(interval: 1, delayStart: false)
        XCTAssertTrue(ops.isPollingOperations)

        if XCTWaiter.wait(for: [exp], timeout: 5) == XCTWaiter.Result.timedOut {
            XCTAssertEqual(delegate.loadingCount, 1, "only one loading should be made")
            XCTAssertTrue(ops.isPollingOperations, "Polling should be active")
            exp.fulfill()
        } else {
            XCTFail("expectation should not have been met")
        }
        
        // After the pause, reactive the app again and check if it was continued
        
        let exp2 = expectation(description: "Polling pause expectation")
        let delegate2 = OpDelegate { count in
            if count == 1 {
                self.ops.stopPollingOperations()
                exp2.fulfill()
            }
        }
        ops.delegate = delegate2
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        wait(for: [exp2], timeout: 5)
        XCTAssertEqual(delegate2.loadingCount, 1, "Loading didnt continue after the active notification")
        XCTAssertFalse(ops.isPollingOperations)
    }
    
    // Testing that operations polling stop works when paused
    func testOperationPollingPauseAndStop() {
        XCTAssertTrue(ops.pollingOptions.contains(.pauseWhenOnBackground), "Operation service is not set to pause on background")
        let exp = expectation(description: "Timeout expectation")
        XCTAssertFalse(ops.isPollingOperations, "Polling should be inactive")
        let delegate = OpDelegate { count in
            if count == 1 {
                // will resign active should stop polling as the app "is on background"
                NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
            }
        }
        ops.delegate = delegate
        ops.startPollingOperations(interval: 1, delayStart: false)
        XCTAssertTrue(ops.isPollingOperations)

        // The expectation should time out
        if XCTWaiter.wait(for: [exp], timeout: 5) == XCTWaiter.Result.timedOut {
            XCTAssertEqual(delegate.loadingCount, 1, "only one loading should be made")
            XCTAssertTrue(ops.isPollingOperations, "Polling should be active")
            exp.fulfill()
        } else {
            XCTFail("expectation should not have been met")
        }
        
        // After the pause, we will stop the polling and "activate" the app again.
        // In such case, the polling should not be started since it was stopped.
        
        let exp2 = expectation(description: "Polling pause expectation")
        let delegate2 = OpDelegate()
        ops.delegate = delegate2
        ops.stopPollingOperations()
        XCTAssertFalse(ops.isPollingOperations)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        if XCTWaiter.wait(for: [exp2], timeout: 5) == XCTWaiter.Result.timedOut {
            XCTAssertEqual(delegate2.loadingCount, 0, "Loading continued after the active notification")
            XCTAssertFalse(ops.isPollingOperations)
            exp2.fulfill()
        } else {
            XCTFail("expectation should not have been met")
        }
    }
}

private class OpDelegate: WMTOperationsDelegate {
    
    private let loadingCountCallback: ((Int) -> Void)?
    private(set) var loadingCount = 0
    
    init(loadingCountCallback: ((Int) -> Void)? = nil) {
        self.loadingCountCallback = loadingCountCallback
    }
    
    func operationsLoading(loading: Bool) {
        if loading {
            loadingCount += 1
            loadingCountCallback?(loadingCount)
        }
    }
    
    func operationsChanged(operations: [WMTUserOperation], removed: [WMTUserOperation], added: [WMTUserOperation]) {
        
    }
    
    func operationsFailed(error: WMTError) {
        
    }
}
