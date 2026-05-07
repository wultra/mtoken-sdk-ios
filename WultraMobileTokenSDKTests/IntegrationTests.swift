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
import Testing
@testable import WultraMobileTokenSDK

/**
 For integration test to be successfully executed, you need to provide
 configuration json file. To more information, visit `WultraMobileTokenSDKTests/Configs/Readme.md`.
 */

final class IntegrationTests {
    
    private let proxy: IntegrationProxy
    private let wmt: WultraMobileToken
    private var pa: PowerAuthSDK { proxy.powerAuth! }
    private var ops: WMTOperations { wmt.operations }
    private var inbox: WMTInbox { wmt.inbox }
    private var push: WMTPush { wmt.push }
    
    private let pin = "1234"
    
    init() async throws {
        WMTLogger.verboseLevel = .debug
        let loaded = try #require(TestConfiguration.load(), "Missing config.json — see WultraMobileTokenSDKTests/Configs/Readme.md")
        proxy = IntegrationProxy(config: loaded.config, pin: pin)
        try await proxy.initializePowerauth()
        try await proxy.prepareActivation()
        wmt = try proxy.powerAuth!.createWultraMobileToken()
    }
    
    deinit {
        let auth = PowerAuthAuthentication.possessionWithPassword(password: pin)
        let semaphore = DispatchSemaphore(value: 0)
        if let pa = proxy.powerAuth {
            pa.removeActivation(with: auth) { _ in
                semaphore.signal()
            }
            semaphore.wait()
        }
    }
    
    /// By default, operation list should be empty
    @Test
    func testList() async throws {
        let operations = try await ops.getOperations()
        #expect(operations.isEmpty)
    }
    
    /// Test of the getOperations WMTCancellable
    @Test
    func testCancelList() async throws {
        var callbackCalled = false
        let list = ops.getOperations { _ in
            callbackCalled = true
            Issue.record("Operation should be already canceled")
        }
        list.cancel()
        try await Task.sleep(nanoseconds: 4_000_000_000)
        #expect(list.isCanceled, "WMTCancellable should be cancelled")
        #expect(!callbackCalled)
    }
    
    /// Operation IDs should be equal
    @Test
    func testDetail() async throws {
        let op = try await proxy.createNonPersonalisedPACOperation()
        let operation = try await ops.getDetail(operationId: op.operationId)
        #expect(op.operationId == operation.id)
    }
    
    @Test
    func testOperationCanceledWithReason() async throws {
        let cancelReason = "PREARRANGED_REASON"
        let op = try await proxy.createOperation()
        _ = try await proxy.cancelOperation(operationId: op.operationId, reason: cancelReason)
        let auth = PowerAuthAuthentication.possessionWithPassword(password: pin)
        let operations = try await ops.getHistory(authentication: auth)
        let opFromList = try #require(operations.first(where: { $0.id == op.operationId }), "Created operation was not in the history")
        #expect(opFromList.statusReason == cancelReason, "statusReason and cancelReason must be the same")
    }
    
    /// Operation IDs should be equal
    @Test
    func testClaim() async throws {
        let op = try await proxy.createNonPersonalisedPACOperation()
        let operation = try await ops.claim(operationId: op.operationId)
        guard operation.ui?.preApprovalScreens?[0].type == .qr else {
            return
        }
        let totpOP = try await proxy.getOperation(operationId: op.operationId)
        let proximityOtp = try #require(totpOP.proximityOtp, "Even with proximityCheckEnabled: true, proximityOtp is nil")
        operation.proximityCheck = WMTProximityCheck(totp: proximityOtp, type: .qrCode)
        let wrongAuth = PowerAuthAuthentication.possessionWithPassword(password: "xxxx")
        do {
            try await ops.authorize(operation: operation, with: wrongAuth)
            Issue.record("Operation approved with wrong password")
        } catch {
            let auth = PowerAuthAuthentication.possessionWithPassword(password: pin)
            try await ops.authorize(operation: operation, with: auth)
        }
    }
    
    /// `currentServerDate` was removed from WMTOperations in favor of more precise powerAuth timeService
    @Test
    func testCurrentServerDate() {
        var synchronizedServerDate: Date?
        let timeService = pa.timeSynchronizationService
        if timeService.isTimeSynchronized {
            synchronizedServerDate = Date(timeIntervalSince1970: timeService.currentTime())
        }
        #expect(synchronizedServerDate != nil)
    }
    
    /// Test of Payment approval (2FA)
    @Test
    func testApprovePayment() async throws {
        _ = try await proxy.createOperation()
        let operations = try await ops.getOperations()
        #expect(operations.count == 1, "1 operation expected. Actual: \(operations.count)")
        let operation = try #require(operations.first)
        let wrongAuth = PowerAuthAuthentication.possessionWithPassword(password: "xxxx")
        do {
            try await ops.authorize(operation: operation, with: wrongAuth)
            Issue.record("Operation approved with wrong password")
        } catch {
            let auth = PowerAuthAuthentication.possessionWithPassword(password: pin)
            try await ops.authorize(operation: operation, with: auth)
        }
    }
    
    /// Test of Payment rejecting (1FA)
    @Test
    func testRejectPayment() async throws {
        let op = try await proxy.createOperation()
        let operations = try await ops.getOperations()
        let opToReject = try #require(operations.first(where: { $0.id == op.operationId }), "Operation was not in the operation list")
        try await ops.reject(operation: opToReject, with: .unexpectedOperation)
    }
    
    /// Test of Payment approval (2FA)
    @Test
    func testMobileTokenData() async throws {
        let op = try await proxy.createOperation()
        let detail = try await ops.getDetail(operationId: op.operationId)
        detail.mobileTokenData = [
            "test1": 1,
            "test2": 2.3,
            "test3": "string",
            "test4": [
                "nested": true
            ]
        ]
        try await ops.authorize(operation: detail, with: PowerAuthAuthentication.possessionWithPassword(password: pin))
        let finalOp = try await proxy.getOperation(operationId: op.operationId)
        let mtd = try #require(finalOp.additionalData?.mobileTokenData, "mobileTokenData not in additionalData")
        #expect(mtd.test1 == 1, "test1 should be 1")
        #expect(mtd.test2 == 2.3, "test2 should be 2.3")
        #expect(mtd.test3 == "string", "test3 should be 'string'")
        #expect(mtd.test4?["nested"] == true, "test4 should be a nested object with 'nested' key")
    }
    
    @Test
    func testMobileTokenDataWithMoBileTokenBuilder() async throws {
        let op = try await proxy.createOperation()
        let detail = try await ops.getDetail(operationId: op.operationId)
        let builder = WMTMobileTokenData.Builder(initialData: ["test1": 8])
        builder
            .put("test2", 0.82)
            .put("test3", "someString")
        let recorder = WMTPreApprovalScreensRecorder(powerAuthSDK: proxy.powerAuth!)
            .begin("intro-warning")
            .end("intro-warning", action: .close)
            .begin("intro-warning")
            .end("intro-warning", action: .continue)
            .begin("qr")
            .end("qr", action: .scan)
            .begin("call-or-confirm")
            .end("call-or-confirm", action: .continue)
        builder.put(recorder)
        detail.mobileTokenData = builder.build()
        let auth = PowerAuthAuthentication.possessionWithPassword(password: pin)
        try await ops.authorize(operation: detail, with: auth)
        let finalOp = try await proxy.getOperation(operationId: op.operationId)
        let mtd = try #require(finalOp.additionalData?.mobileTokenData, "mobileTokenData not in additionalData")
        #expect(mtd.test1 == 8, "test1 should be 8")
        #expect(mtd.test2 == 0.82, "test2 should be '0.82'")
        #expect(mtd.test3 == "someString", "test2 should be 'someString'")
        let screens = try #require(mtd.preApprovalScreens, "preApprovalScreens missing or invalid shape")
        #expect(screens.count == 4, "Expected two screen visits")
        #expect(screens[0].screen == "intro-warning")
        #expect(screens[0].action == "CLOSE")
        #expect(screens[0].timestampOpened != nil)
        #expect(screens[0].timestampClosed != nil)
        #expect(screens[1].screen == "intro-warning")
        #expect(screens[1].action == "CONTINUE")
        #expect(screens[1].timestampOpened != nil)
        #expect(screens[1].timestampClosed != nil)
        #expect(screens[2].screen == "qr")
        #expect(screens[2].action == "SCAN")
        #expect(screens[2].timestampOpened != nil)
        #expect(screens[2].timestampClosed != nil)
        #expect(screens[3].screen == "call-or-confirm")
        #expect(screens[3].action == "CONTINUE")
        #expect(screens[3].timestampOpened != nil)
        #expect(screens[3].timestampClosed != nil)
    }
    
    @Test
    func testMobileTokenDataCustomRecord() async throws {
        final class CustomRecord: WMTMobileTokenDataRecord {
            static let key = "customRecord"
            var key: String { Self.key }
            private var data: [String: Encodable] = [:]
            
            @discardableResult
            func add(_ name: String, _ value: Encodable) -> Self {
                data[name] = value
                return self
            }
            
            func build() -> Encodable {
                data.toAnyEncodable()
            }
        }
        
        let op = try await proxy.createOperation()
        let detail = try await ops.getDetail(operationId: op.operationId)
        let builder = WMTMobileTokenData.Builder()
        let record = CustomRecord()
            .add("flag", true)
            .add("mode", "debug")
        builder.put(record.key, record.build())
        detail.mobileTokenData = builder.build()
        let auth = PowerAuthAuthentication.possessionWithPassword(password: pin)
        try await ops.authorize(operation: detail, with: auth)
        let finalOp = try await proxy.getOperation(operationId: op.operationId)
        let mtd = try #require(finalOp.additionalData?.mobileTokenData, "mobileTokenData not found in additionalData")
        let custom = try #require(mtd.customRecord, "customRecord missing or malformed")
        #expect(custom.flag == true)
        #expect(custom.mode == "debug")
    }
    
    @Test
    func testRejectPaymentWithMobileTokenData() async throws {
        let op = try await proxy.createOperation()
        let operations = try await ops.getOperations()
        let opToReject = try #require(operations.first(where: { $0.id == op.operationId }), "Operation was not in the operation list")
        opToReject.mobileTokenData = [
            "test1": 1,
            "test2": 2.3,
            "test3": "string",
            "test4": ["nested": true]
        ]
        try await ops.reject(operation: opToReject, with: .preApproval)
        let finalOp = try await proxy.getOperation(operationId: op.operationId)
        let mtd = try #require(finalOp.additionalData?.mobileTokenData, "mobileTokenData not in additionalData")
        #expect(mtd.test1 == 1, "test1 should be 1")
        #expect(mtd.test2 == 2.3, "test2 should be 2.3")
        #expect(mtd.test3 == "string", "test3 should be 'string'")
        #expect(mtd.test4?["nested"] == true, "test4 should be a nested object with 'nested' key")
    }
    
    /// Testing that operation polling works.
    @Test
    func testOperationPolling() async throws {
        #expect(!ops.isPollingOperations)
        let delegate = OpDelegate()
        let signal = AsyncTestSignal()
        delegate.loadingCountCallback = { count in
            if count == 3 {
                self.ops.stopPollingOperations()
                Task { await signal.fulfill() }
            }
        }
        ops.delegate = delegate
        ops.startPollingOperations(interval: 5, delayStart: false)
        #expect(ops.isPollingOperations)
        try await wait(for: signal, timeout: 30)
        #expect(!ops.isPollingOperations)
    }
    
    @Test
    func testHistory() async throws {
        let op = try await proxy.createOperation()
        let auth = PowerAuthAuthentication.possessionWithPassword(password: pin)
        let operations = try await ops.getHistory(authentication: auth)
        let opFromList = try #require(operations.first(where: { $0.id == op.operationId }), "Created operation was not in the history")
        #expect(opFromList.status == .pending)
    }
    
    @Test
    func testOperationChangedDelegate() async throws {
        let d1 = OpDelegate()
        let d2 = OpDelegate()
        let d3 = OpDelegate()
        let d4 = OpDelegate()
        
        let signal1 = AsyncTestSignal()
        d1.changedCallback = { all, removed, added in
            #expect(all.count == 1)
            #expect(removed.isEmpty)
            #expect(added.count == 1)
            Task { await signal1.fulfill() }
        }
        ops.delegate = d1
        _ = try await proxy.createOperation()
        ops.refreshOperations()
        try await wait(for: signal1, timeout: 4)
        
        let signal2 = AsyncTestSignal()
        d2.changedCallback = { all, removed, added in
            #expect(all.count == 2)
            #expect(removed.isEmpty)
            #expect(added.count == 1)
            Task { await signal2.fulfill() }
        }
        ops.delegate = d2
        _ = try await proxy.createOperation()
        ops.refreshOperations()
        try await wait(for: signal2, timeout: 4)
        
        ops.delegate = nil
        let operations = try await ops.getOperations()
        #expect(operations.count == 2)
        
        let signal3 = AsyncTestSignal()
        d3.changedCallback = { all, removed, added in
            #expect(all.count == 1)
            #expect(added.isEmpty)
            #expect(removed.count == 1)
            Task { await signal3.fulfill() }
        }
        ops.delegate = d3
        try await ops.reject(operation: operations[0], with: .unknown)
        try await wait(for: signal3, timeout: 4)
        
        let signal4 = AsyncTestSignal()
        d4.changedCallback = { all, removed, added in
            #expect(all.isEmpty)
            #expect(added.isEmpty)
            #expect(removed.count == 1)
            Task { await signal4.fulfill() }
        }
        ops.delegate = d4
        let auth = PowerAuthAuthentication.possessionWithPassword(password: pin)
        try await ops.authorize(operation: operations[1], with: auth)
        try await wait(for: signal4, timeout: 2)
        ops.delegate = nil
        let finalOperations = try await ops.getOperations()
        #expect(finalOperations.count == 0)
    }
    
    @Test
    func testQROperation() async throws {
        let measure = MeasureElapsed("QROperation")
        let op = try await proxy.createOperation()
        measure.mark("Operation created")
        let qrData = try await proxy.getQROperation(operationId: op.operationId)
        measure.mark("QR data retrieved")
        let qrOp = try WMTQROperationParser().parse(string: qrData.operationQrCodeData).get()
        let auth = PowerAuthAuthentication.possessionWithPassword(password: pin)
        let otp = try await ops.authorize(qrOperation: qrOp, authentication: auth)
        measure.mark("Authorized")
        let verified = try await proxy.verifyQROperation(operationId: op.operationId, operationData: qrData, otp: otp)
        measure.mark("OTP verified")
        print("Operation verified with \(verified.otpValid.description) result")
        #expect(verified.otpValid, "Failed to verify QR operation")
    }
    
    // MARK: - Push
    
    @Test
    func testRegisterPushApns() async throws {
        try await push.register(to: .apns(token: "testtoken".data(using: .utf8)!))
    }
    
    @Test
    func testRegisterPushApnsProduction() async throws {
        try await push.register(to: .apns(token: "testtoken".data(using: .utf8)!, environment: .production))
    }
    
    @Test
    func testRegisterPushApnsDevelopment() async throws {
        try await push.register(to: .apns(token: "testtoken".data(using: .utf8)!, environment: .development))
    }
    
    @Test
    func testRegisterPushFcm() async throws {
        try await push.register(to: .fcm(token: "testtoken"))
    }
    
    // MARK: - Inbox
    
    @Test
    func testInboxMessages() async throws {
        let messagesToTest = 5
        let messages = try await prepareMessages(count: messagesToTest)
        let unreadCount = try await fetchUnreadMessagesCount()
        #expect(messagesToTest == unreadCount)
        let messageList = try await inbox.getMessageList(pageNumber: 0, pageSize: 50, onlyUnread: true)
        #expect(messagesToTest == messageList.count)
        compareMessages(expected: messages, received: messageList)
        let firstMessage = try #require(messages.first)
        let messageDetail = try await inbox.getMessageDetail(messageId: firstMessage.id)
        #expect(firstMessage.id == messageDetail.id)
        #expect(firstMessage.subject == messageDetail.subject)
        #expect(firstMessage.summary == messageDetail.summary)
        #expect(firstMessage.body == messageDetail.body)
        #expect(firstMessage.read == messageDetail.read)
        #expect(firstMessage.type == messageDetail.type.rawValue)
        #expect(floor(firstMessage.timestamp.timeIntervalSince1970) == floor(messageDetail.timestampCreated.timeIntervalSince1970))
    }
    
    @Test
    func testGetAllInboxMessages() async throws {
        let count = 11
        let messages = try await prepareMessages(count: count, type: "html")
        let receivedMessages = try await inbox.getAllMessages(pageSize: 5)
        #expect(count == receivedMessages.count)
        compareMessages(expected: messages, received: receivedMessages)
    }
    
    @Test
    func testMarkMessageRead() async throws {
        let count = 4
        let messages = try await prepareMessages(count: count)
        var receivedMessages = try await fetchAllMessages()
        #expect(count == receivedMessages.count)
        compareMessages(expected: messages, received: receivedMessages)
        let messageId = receivedMessages[0].id
        try await inbox.markRead(messageId: messageId)
        let detail = try await inbox.getMessageDetail(messageId: messageId)
        #expect(detail.read)
        receivedMessages = try await fetchAllMessages(onlyUnread: true)
        #expect(count - 1 == receivedMessages.count)
        #expect(receivedMessages.findMessage(messageId: messageId) == nil)
        receivedMessages = try await fetchAllMessages(onlyUnread: false)
        #expect(count == receivedMessages.count)
        let alreadyRead = try #require(receivedMessages.findMessage(messageId: messageId))
        #expect(alreadyRead.read)
    }
    
    @Test
    func testMarkAllMessagesRead() async throws {
        let count = 4
        let messages = try await prepareMessages(count: count)
        let receivedMessages = try await fetchAllMessages()
        #expect(count == receivedMessages.count)
        compareMessages(expected: messages, received: receivedMessages)
        try await inbox.markAllRead()
        let allMsgsRead = try await inbox.getAllMessages(onlyUnread: false)
        let allMsgsUnread = try await inbox.getAllMessages(onlyUnread: true)
        #expect(0 == allMsgsUnread.count)
        #expect(count == allMsgsRead.count)
    }
    
    // Support functions
    
    private func fetchUnreadMessagesCount() async throws -> Int {
        try await inbox.getUnreadCount().countUnread
    }
    
    private func fetchAllMessages(onlyUnread: Bool = false) async throws -> [WMTInboxMessage] {
        try await inbox.getAllMessages(onlyUnread: onlyUnread)
    }
    
    private func prepareMessages(count: Int, type: String = "text") async throws -> [InboxMessageDetail] {
        let messages = try await proxy.createInboxMessages(count: count, defaultType: type)
        #expect(count == messages.count)
        return messages
    }
    
    private func compareMessages(expected: [InboxMessageDetail], received: [WMTInboxMessage]) {
        for e in expected {
            guard let r = received.findMessage(messageId: e.id) else {
                Issue.record("Message \(e.id) not found")
                continue
            }
            #expect(e.read == r.read)
            #expect(e.subject == r.subject)
            #expect(e.summary == r.summary)
            #expect(e.type == r.type.rawValue)
            #expect(floor(e.timestamp.timeIntervalSince1970) == floor(r.timestampCreated.timeIntervalSince1970))
        }
    }
}

private class OpDelegate: WMTOperationsDelegate {
    
    var loadingCountCallback: ((Int) -> Void)?
    var changedCallback: ((_ operations: [WMTUserOperation], _ removed: [WMTUserOperation], _ added: [WMTUserOperation]) -> Void)?
    private(set) var loadingCount = 0
    
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
        if let index = firstIndex(where: { $0.id == messageId }) {
            return self[index]
        }
        return nil
    }
}

class MeasureElapsed {
    
    private let started = Date()
    private let name: String
    
    init(_ name: String) {
        self.name = name
        print("Measuring elapsed time: \(name)")
    }
    
    func mark(_ reason: String? = nil) {
        print("Elapsed time for '\(name)\(reason != nil ? ":\(reason!)" : "")' - \(String(format: "%.3f", Date().timeIntervalSince(started)))s.")
    }
}
