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
    
    private var proxy: IntegrationProxy!
    private var pa: PowerAuthSDK! { proxy.powerAuth }
    private var ops: WMTOperations! { proxy.operations }
    private var inbox: WMTInbox! { proxy.inbox }
    
    private let pin = "1234"
    
    override func setUp() {
        super.setUp()
        WMTLogger.verboseLevel = .debug
        proxy = IntegrationProxy()
        
        let exp = XCTestExpectation(description: "setup expectation")
        
        // Integration Utils prepares an valid activation and sets is as primary
        // token activation on nextstep server
        proxy.prepareActivation(pin: pin) { error in
            if let error = error {
                XCTFail(error)
            }
            exp.fulfill()
        }
        
        let waiter = XCTWaiter()
        waiter.wait(for: [exp], timeout: 20)
    }
    
    override func tearDown() {
        super.tearDown()
        let exp = XCTestExpectation(description: "setup expectation")
        
        // after each batch of tests, remove the activation
        let auth = PowerAuthAuthentication.possessionWithPassword(password: pin)
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
            case .success(let ops):
                XCTAssertTrue(ops.isEmpty)
            case .failure(let err):
                XCTFail(err.description)
            }
            exp.fulfill()
            
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }
    
    
    /// Test of the getOperations WMTCancellable
    func testCancelList() {
        let exp = expectation(description: "Cancel list of operations")
        
        let list = ops.getOperations { result in
            XCTFail("Operation should be already canceled")
            exp.fulfill()
        }
        
        list.cancel()
        
        // Allowing most of the timeout duration for potential completion of the getOperations call.
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            XCTAssertTrue(list.isCanceled, "WMTCancellable should be cancelled")
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    /// Operation IDs should be equal
    func testDetail() {
        let exp = expectation(description: "Operation detail")
        
        proxy.createNonPersonalisedPACOperation { op in
            if let op {
                DispatchQueue.main.async {
                    _ = self.ops.getDetail(operationId: op.operationId) { result in
                        switch result {
                        case .success(let operation):
                            XCTAssertEqual(op.operationId, operation.id)
                        case .failure(let err):
                            XCTFail(err.description)
                        }
                        exp.fulfill()
                    }
                }
            } else {
                XCTFail("Failed to get operation detail")
                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }
    
    /// Test of the Operation cancel
    func testDetailCancel() {
        let exp = expectation(description: "Cancel operation detail")
        
        proxy.createNonPersonalisedPACOperation { op in
            if let op {
                DispatchQueue.main.async {
                    guard let operation = self.ops.getDetail(operationId: op.operationId, completion: { _ in
                        XCTFail("Operation should be already canceled")
                        exp.fulfill()
                    }) else {
                        XCTFail("Failed to create operation")
                        exp.fulfill()
                        return
                    }
                    
                    operation.cancel()
                    
                    // Allowing most of the timeout duration for potential completion of the getDetail call.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        XCTAssertTrue(operation.isCancelled, "Operation should be cancelled")
                        exp.fulfill()
                    }
                }
            }
        }
        
        // Wait for expectation to be fulfilled
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testOperationCanceledWithReason() {
        let exp = expectation(description: "Cancel operation with reason")
        let cancelReason = "PREARRANGED_REASON"
        
        proxy.createOperation { op in
            guard let op else {
                XCTFail("Failed to create operation")
                exp.fulfill()
                return
            }
            self.proxy.cancelOperation(operationId: op.operationId, reason: cancelReason) { cancelOp in
                if cancelOp != nil {
                    let auth = PowerAuthAuthentication.possessionWithPassword(password: self.pin)
                    DispatchQueue.main.async {
                        _ = self.ops.getHistory(authentication: auth) { result in
                            switch result {
                            case .success(let ops):
                                if let opFromList = ops.first(where: { $0.operation.id == op.operationId }) {
                                    XCTAssertEqual(opFromList.operation.statusReason, cancelReason, "statusReason and cancelReason must be the same")
                                } else {
                                    XCTFail("Created operation was not in the history")
                                }
                            case .failure:
                                XCTFail("History was not retrieved")
                            }
                            exp.fulfill()
                        }
                    }
                } else {
                    XCTFail("Failed to cancel operation")
                    exp.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 20, handler: nil)
    }
    
    /// Operation IDs should be equal
    func testClaim() {
        let exp = expectation(description: "Operation Claim should return UserOperation with operation.id")
        
        proxy.createNonPersonalisedPACOperation { op in
            if let op {
                DispatchQueue.main.async {
                    _ = self.ops.claim(operationId: op.operationId) { result in
                        switch result {
                        case .success(let operation):
                            if operation.ui?.preApprovalScreen?.type == .qr {
                                self.proxy.getOperation(operation: op) { totpOP in
                                    XCTAssertNotNil(totpOP?.proximityOtp, "Even with proximityCheckEnabled: true, in proximityOtp nil")
                                    if let totpOP = totpOP, let proximityOtp = totpOP.proximityOtp {
                                        operation.proximityCheck = WMTProximityCheck(totp: proximityOtp, type: .qrCode)
                                        //  wrong password on purpose
                                        let auth = PowerAuthAuthentication.possessionWithPassword(password: "xxxx")
                                        self.ops.authorize(operation: operation, with: auth) { result in
                                            switch result {
                                            case .failure:
                                                let auth = PowerAuthAuthentication.possessionWithPassword(password: self.pin)
                                                self.ops.authorize(operation: operation, with: auth) { result in
                                                    if case .failure(let error) = result {
                                                        XCTFail("Failed to authorize op: \(error.description)")
                                                    }
                                                    exp.fulfill()
                                                }
                                            case .success:
                                                XCTFail("Operation approved with wrong password")
                                                exp.fulfill()
                                            }
                                        }
                                    } else {
                                        XCTFail("Operation or TOTP is NIL")
                                        exp.fulfill()
                                    }
                                }
                            }
  
                            case .failure(let err):
                                XCTFail(err.description)
                                exp.fulfill()
                            }
                        }
                    }
            } else {
                XCTFail("Failed to get operation detail")
                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: 20, handler: nil)
    }
    
    /// `currentServerDate` was removed from WMTOperations in favor of more precise powerAuth timeService
    func testCurrentServerDate() {
        var synchronizedServerDate: Date? = nil
        
        let timeService = pa.timeSynchronizationService
        if timeService.isTimeSynchronized {
            synchronizedServerDate = Date(timeIntervalSince1970: timeService.currentTime())
        }
        
        XCTAssertNotNil(synchronizedServerDate)
    }
    
    /// Test of Login operation approval (1FA)
    /// TODO: prepare 1FA op
//    func testApproveLogin() {
//
//        let exp = expectation(description: "Approve login")
//
//        proxy.createOperation { error in
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
//        proxy.createOperation { error in
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
        
        proxy.createOperation { op in
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
                        //  wrong password on purpose
                        let auth = PowerAuthAuthentication.possessionWithPassword(password: "xxxx")
                        self.ops.authorize(operation: ops.first!, with: auth) { result in
                            switch result {
                            case .failure:
                                let auth = PowerAuthAuthentication.possessionWithPassword(password: self.pin)
                                self.ops.authorize(operation: ops.first!, with: auth) { result in
                                    if case .failure(let error) = result {
                                        XCTFail("Failed to authorize op: \(error.description)")
                                    }
                                    exp.fulfill()
                                }
                            case .success:
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
        
        proxy.createOperation { op in
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
                        self.ops.reject(operation: opToReject, with: .unexpectedOperation) { result in
                            if case .failure(let error) = result {
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
        let delegate = OpDelegate()
        delegate.loadingCountCallback = { count in
            if count == 3 {
                self.ops.stopPollingOperations()
                exp.fulfill()
            }
        }
        ops.delegate = delegate
        ops.startPollingOperations()
        XCTAssertTrue(ops.isPollingOperations)

        waitForExpectations(timeout: 30, handler: nil)
        
        XCTAssertFalse(ops.isPollingOperations)
    }
    
    func testHistory() {
        let exp = expectation(description: "history expectation")
        
        // lets create 1 operation and leave it in the state of "pending"
        proxy.createOperation { op in
            
            guard let op = op else {
                XCTFail("Failed to create operation")
                exp.fulfill()
                return
            }
            
            let auth = PowerAuthAuthentication.possessionWithPassword(password: self.pin)
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
        let delegate = OpDelegate()
        delegate.loadingCountCallback = { count in
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
        let delegate2 = OpDelegate()
        delegate2.loadingCountCallback = { count in
            if count == 1 {
                self.ops.stopPollingOperations()
                exp2.fulfill()
            }
        }
        ops.delegate = delegate2
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        wait(for: [exp2], timeout: 5)
        XCTAssertEqual(delegate2.loadingCount, 1, "Loading did continue after the active notification")
        XCTAssertFalse(ops.isPollingOperations)
    }
    
    // Testing that operations polling stop works when paused
    func testOperationPollingPauseAndStop() {
        XCTAssertTrue(ops.pollingOptions.contains(.pauseWhenOnBackground), "Operation service is not set to pause on background")
        let exp = expectation(description: "Timeout expectation")
        XCTAssertFalse(ops.isPollingOperations, "Polling should be inactive")
        let delegate = OpDelegate()
        delegate.loadingCountCallback = { count in
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
    
    func testOperationChangedDelegate() {
        
        // overall process expectation
        let exp = expectation(description: "Operation delegates called properly")
        
        // expectation for each delegate
        let expD1 = expectation(description: "Delegate 1 was handeled")
        let expD2 = expectation(description: "Delegate 2 was handeled")
        let expD3 = expectation(description: "Delegate 3 was handeled")
        let expD4 = expectation(description: "Delegate 4 was handeled")
        
        // keeping the delegates to retain the objects
        let d1 = OpDelegate()
        let d2 = OpDelegate()
        let d3 = OpDelegate()
        let d4 = OpDelegate()
        
        // first delegate confirms adding 1 operation to empty list
        d1.changedCallback = { all, removed, added in
            XCTAssertEqual(all.count, 1)
            XCTAssertTrue(removed.isEmpty)
            XCTAssertEqual(added.count, 1)
            expD1.fulfill()
        }
        ops.delegate = d1
        
        proxy.createOperation { op in
            
            guard op != nil else {
                XCTFail("Failed to create operation")
                exp.fulfill()
                return
            }
            
            // refresh operation to trigger onChanged callback
            self.ops.refreshOperations()
            self.wait(for: [expD1], timeout: 4)
            
            // second delegate confirms adding 1 operation to list with 1 operation already added
            d2.changedCallback = { all, removed, added in
                XCTAssertEqual(all.count, 2)
                XCTAssertTrue(removed.isEmpty)
                XCTAssertEqual(added.count, 1)
                expD2.fulfill()
            }
            self.ops.delegate = d2
            
            self.proxy.createOperation { op2 in
                
                guard op2 != nil else {
                    XCTFail("Failed to create operation")
                    exp.fulfill()
                    return
                }
                
                // refresh operation to trigger onChanged callback
                self.ops.refreshOperations()
                self.wait(for: [expD2], timeout: 4)
                
                self.ops.delegate = nil // to disable repeated call on d2 fullfill
                self.ops.getOperations { rOps in
                    
                    guard case .success(let ops) = rOps else {
                        XCTFail("Failed to retreive ops")
                        exp.fulfill()
                        return
                    }
                    
                    guard ops.count == 2 else {
                        XCTFail("\(ops.count) operations retreived instead of 2")
                        exp.fulfill()
                        return
                    }
                    XCTAssertEqual(ops.count, 2) // just to make a point
                    
                    // third delegate confirms properly removed operation after reject
                    d3.changedCallback = { all, removed, added in
                        XCTAssertEqual(all.count, 1)
                        XCTAssertTrue(added.isEmpty)
                        XCTAssertEqual(removed.count, 1)
                        expD3.fulfill()
                    }
                    self.ops.delegate = d3
                    
                    self.ops.reject(operation: ops[0], with: .unknown) { result in
                        
                        switch result {
                        case .failure(let error):
                            XCTFail("Failed to reject operation: \(error)")
                            exp.fulfill()
                            return
                        case .success:
                            self.wait(for: [expD3], timeout: 4)
                            
                            // last delegate confirms properly removed operation after authorize
                            d4.changedCallback = { all, removed, added in
                                XCTAssertTrue(all.isEmpty)
                                XCTAssertTrue(added.isEmpty)
                                XCTAssertEqual(removed.count, 1)
                                expD4.fulfill()
                            }
                            self.ops.delegate = d4
                            
                            let auth = PowerAuthAuthentication.possessionWithPassword(password: self.pin)
                            self.ops.authorize(operation: ops[1], with: auth) { result2 in
                                
                                switch result2 {
                                case .failure(let error):
                                    XCTFail("Failed to reject operation: \(error)")
                                    exp.fulfill()
                                    return
                                case .success:
                                    self.wait(for: [expD4], timeout: 2)
                                    self.ops.delegate = nil // to disable repeated call on d4 fullfill
                                    
                                    // final confirm that there are no operation left to resolve
                                    self.ops.getOperations { resultOps in
                                        switch resultOps {
                                        case .success(let ops):
                                            XCTAssertEqual(ops.count, 0)
                                        case .failure(let error):
                                            XCTFail("Failed to reject operation: \(error)")
                                        }
                                        exp.fulfill()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        wait(for: [exp], timeout: 10)
    }
    
    func testQROperation() {
        let exp = expectation(description: "QR Operation integration test")
        
        // create regular operation
        proxy.createOperation { op in
            
            guard let op = op else {
                XCTFail("Failed to create operation")
                exp.fulfill()
                return
            }
            
            // get QR data of the operation
            self.proxy.getQROperation(operation: op) { qrData in
                guard let qrData = qrData else {
                    XCTFail("Failed to retrieve QR data")
                    exp.fulfill()
                    return
                }
                
                // parse the data
                switch WMTQROperationParser().parse(string: qrData.operationQrCodeData) {
                case .success(let qrOp):
                    
                    let auth = PowerAuthAuthentication.possessionWithPassword(password: self.pin)
                    
                    // get the OTP with the "offline" signing
                    _ = self.ops.authorize(qrOperation: qrOp, authentication: auth) { qrAuthResult in
                        switch qrAuthResult {
                        case .success(let otp):
                            
                            // verify the operation on the backend with the OTP
                            self.proxy.verifyQROperation(operation: op, operationData: qrData, otp: otp) { verified in
                                
                                print("Operation verified with \(verified?.otpValid.description ?? "ERROR") result")
                                
                                // success?
                                if verified?.otpValid == true {
                                    exp.fulfill()
                                } else {
                                    XCTFail("Failed to verify QR operation")
                                    exp.fulfill()
                                }
                            }
                        case .failure:
                            XCTFail("Failed to authorize QR operation")
                            exp.fulfill()
                        }
                    }
                case .failure:
                    XCTFail("Failed to parse QR operation")
                    exp.fulfill()
                }
            }
        }
        // there are 3 backend calls, give it some time...
        waitForExpectations(timeout: 20, handler: nil)
    }
    
    // MARK: - Inbox
    
    func testInboxMessages() {
        let messagesToTest = 5
        let messages = prepareMessages(count: messagesToTest)
        let unreadCount = fetchUnreadMessagesCount()
        XCTAssertEqual(messagesToTest, unreadCount)
        
        // Read all messages at once
        let getMessages = expectation(description: "Get inbox messages list")
        var messageList = [WMTInboxMessage]()
        inbox.getMessageList(pageNumber: 0, pageSize: 50, onlyUnread: true) { result in
            switch result {
            case .success(let messages):
                XCTAssertEqual(messagesToTest, messages.count)
                messageList = messages
            case .failure(let error):
                XCTFail("Request failed with error: \(error)")
            }
            getMessages.fulfill()
        }
        XCTWaiter().wait(for: [getMessages], timeout: 20)
        
        // Now test received messages
        compareMessages(expected: messages, received: messageList)
        
        // Try to get message detail
        var messageDetail: WMTInboxMessageDetail?
        let firstMessage = messages.first!
        let getMessageDetail = expectation(description: "Get message detail")
        inbox.getMessageDetail(messageId: firstMessage.id) { result in
            switch result {
            case .success(let detail):
                messageDetail = detail
            case .failure(let error):
                XCTFail("Request failed with error: \(error)")
            }
            getMessageDetail.fulfill()
        }
        XCTWaiter().wait(for: [getMessageDetail], timeout: 20)
        
        XCTAssertNotNil(messageDetail)
        XCTAssertEqual(firstMessage.id, messageDetail?.id)
        XCTAssertEqual(firstMessage.subject, messageDetail?.subject)
        XCTAssertEqual(firstMessage.summary, messageDetail?.summary)
        XCTAssertEqual(firstMessage.body, messageDetail?.body)
        XCTAssertEqual(firstMessage.read, messageDetail?.read)
        XCTAssertEqual(firstMessage.type, messageDetail?.type.rawValue)
        XCTAssertEqual(floor(firstMessage.timestamp.timeIntervalSince1970), floor(messageDetail!.timestampCreated.timeIntervalSince1970))
    }
    
    func testGetAllInboxMessages() {
        let count = 11
        let messages = prepareMessages(count: count, type: "html")
        var receivedMessages = [WMTInboxMessage]()
        let getAllMessages = expectation(description: "Get all messages")
        inbox.getAllMessages(pageSize: 5) { result in
            switch result {
            case .success(let msgs):
                receivedMessages = msgs
                
            case .failure:
                XCTFail()
            }
            getAllMessages.fulfill()
        }
        XCTWaiter().wait(for: [getAllMessages], timeout: 20)
        XCTAssertEqual(count, receivedMessages.count)
        compareMessages(expected: messages, received: receivedMessages)
    }
    
    func testMarkMessageRead() {
        let count = 4
        let messages = prepareMessages(count: count)
        var receivedMessages = fetchAllMessages()
        XCTAssertEqual(count, receivedMessages.count)
        compareMessages(expected: messages, received: receivedMessages)
        
        // Mark first as read and receive its detail
        let setMessageAsRead = expectation(description: "Set message as read")
        let readMessageDetail = expectation(description: "Get read message's detail")
        let messageId = receivedMessages[0].id
        inbox.markRead(messageId: messageId) { result in
            switch result {
            case .success:
                // If success, then read message detail and test whether the message was set as read
                self.inbox.getMessageDetail(messageId: messageId) { result in
                    switch result {
                    case .success(let detail):
                        XCTAssertTrue(detail.read)
                    case .failure:
                        XCTFail()
                    }
                    readMessageDetail.fulfill()
                }
            case .failure:
                XCTFail()
                readMessageDetail.fulfill()
            }
            setMessageAsRead.fulfill()
        }
        XCTWaiter().wait(for: [setMessageAsRead, readMessageDetail], timeout: 20)
        
        // Now update list
        receivedMessages = fetchAllMessages(onlyUnread: true)
        XCTAssertEqual(count - 1, receivedMessages.count)
        XCTAssertNil(receivedMessages.findMessage(messageId: messageId))
        
        receivedMessages = fetchAllMessages(onlyUnread: false)
        XCTAssertEqual(count, receivedMessages.count)
        let alreadyRead = receivedMessages.findMessage(messageId: messageId)
        XCTAssertNotNil(alreadyRead)
        XCTAssertTrue(alreadyRead?.read ?? false)
    }
    
    func testMarkAllMessagesRead() {
        let count = 4
        let messages = prepareMessages(count: count)
        let receivedMessages = fetchAllMessages()
        XCTAssertEqual(count, receivedMessages.count)
        compareMessages(expected: messages, received: receivedMessages)
        
        // Mark first as read and receive its detail
        let setMessagesAsRead = expectation(description: "Set all messages as read")
        let allReadMessages = expectation(description: "Get all messages (read)")
        let allUnreadMessages = expectation(description: "Get all messages (unread)")
        
        var allMsgsRead = [WMTInboxMessage]()
        var allMsgsUnread = [WMTInboxMessage]()
        inbox.markAllRead { result in
            switch result {
            case .success:
                // If success, then read message all messages
                self.inbox.getAllMessages(onlyUnread: false) { result in
                    switch result {
                    case .success(let msgs):
                        allMsgsRead = msgs
                    case .failure:
                        XCTFail()
                    }
                    allReadMessages.fulfill()
                }
                self.inbox.getAllMessages(onlyUnread: true) { result in
                    switch result {
                    case .success(let msgs):
                        allMsgsUnread = msgs
                    case .failure:
                        XCTFail()
                    }
                    allUnreadMessages.fulfill()
                }
            case .failure:
                XCTFail()
                allReadMessages.fulfill()
                allUnreadMessages.fulfill()
            }
            setMessagesAsRead.fulfill()
        }
        XCTWaiter().wait(for: [setMessagesAsRead, allReadMessages, allUnreadMessages], timeout: 20)
        XCTAssertEqual(0, allMsgsUnread.count)
        XCTAssertEqual(count, allMsgsRead.count)
        
        // Now test all messages
    }
    
    // Support functions
    
    private func fetchUnreadMessagesCount() -> Int {
        let getMessagesCount = expectation(description: "Get inbox messages count")
        var receivedCount = -1
        inbox.getUnreadCount { result in
            switch result {
            case .success(let count):
                receivedCount = count.countUnread
            case .failure(let error):
                XCTFail("Request failed with error: \(error)")
            }
            getMessagesCount.fulfill()
        }
        XCTWaiter().wait(for: [getMessagesCount], timeout: 20)
        return receivedCount
    }
    
    private func fetchAllMessages(onlyUnread: Bool = false) -> [WMTInboxMessage] {
        var receivedMessages = [WMTInboxMessage]()
        let getAllMessages = expectation(description: "Get all messages")
        inbox.getAllMessages(onlyUnread: onlyUnread) { result in
            switch result {
            case .success(let msgs):
                receivedMessages = msgs
            case .failure:
                XCTFail()
            }
            getAllMessages.fulfill()
        }
        XCTWaiter().wait(for: [getAllMessages], timeout: 20)
        return receivedMessages
    }
    
    private func prepareMessages(count: Int, type: String = "text") -> [InboxMessageDetail] {
        let prepareExp = expectation(description: "Prepare inbox messages")
        var messages = [InboxMessageDetail]()
        proxy.createInboxMessages(count: count) { msgs in
            messages = msgs
            prepareExp.fulfill()
        }
        XCTWaiter().wait(for: [prepareExp], timeout: 20)
        XCTAssertEqual(count, messages.count)
        return messages
    }
    
    private func compareMessages(expected: [InboxMessageDetail], received: [WMTInboxMessage]) {
        for e in expected {
            guard let r = received.findMessage(messageId: e.id) else {
                XCTFail("Message \(e.id) not found")
                continue
            }
            XCTAssertEqual(e.read, r.read)
            XCTAssertEqual(e.subject, r.subject)
            XCTAssertEqual(e.summary, r.summary)
            XCTAssertEqual(e.type, r.type.rawValue)
            XCTAssertEqual(floor(e.timestamp.timeIntervalSince1970), floor(r.timestampCreated.timeIntervalSince1970))
        }
    }
}


private class OpDelegate: WMTOperationsDelegate {
    
    var loadingCountCallback: ((Int) -> Void)?
    var changedCallback: ((_ operations: [WMTUserOperation], _ removed: [WMTUserOperation], _ added: [WMTUserOperation]) -> Void)?
    private(set) var loadingCount = 0
    
    init() {
        
    }
    
    func operationsLoading(loading: Bool) {
        if loading {
            loadingCount += 1
            loadingCountCallback?(loadingCount)
        }
    }
    
    func operationsChanged(operations: [WMTUserOperation], removed: [WMTUserOperation], added: [WMTUserOperation]) {
        changedCallback?(operations, removed, added)
    }
    
    func operationsFailed(error: WMTError) {
        
    }
}

private extension Array where Element == WMTInboxMessage {
    func findMessage(messageId: String) -> WMTInboxMessage? {
        if let index = self.firstIndex(where: { $0.id == messageId }) {
            return self[index]
        }
        return nil
    }
}
