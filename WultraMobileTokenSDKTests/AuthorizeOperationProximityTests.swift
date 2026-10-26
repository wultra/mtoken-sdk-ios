//
// Copyright 2025 Wultra s.r.o.
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
import Testing
@testable import WultraMobileTokenSDK

/// Integration tests for `WMTOperations.authorize(operation:with:)` and `WMTOperations.reject(operation:with:)`
/// covering the server time alignment of proximity check and `mobileTokenData` timestamps:
/// - No time-sensitive data → authorize/reject directly (no time synchronization)
/// - Time-sensitive data + time already synchronized → adjust timestamps, then authorize/reject
/// - Time-sensitive data + time NOT synchronized → synchronize first, adjust, then authorize/reject
/// - Time-sensitive data + time synchronization FAILS → callback with failure, nothing is sent
/// - Timestamp adjustment logic (zero offset, large offset, custom timestampReceived)
/// - Only top-level `WMTPreApprovalScreensRecorder` data is aligned
/// - Canceling the returned operation during or after the time synchronization
final class AuthorizeOperationProximityTests: BaseIntegrationTests {

    // MARK: - Mock: PowerAuthTimeSynchronizationService

    /// Mock time service that reports time as synchronized with a configurable offset.
    /// `offsetSeconds`: positive = server ahead of device, negative = server behind.
    private class SynchronizedTimeService: NSObject, PowerAuthTimeSynchronizationService {
        func resetTimeSynchronization() { }

        let offsetSeconds: TimeInterval

        init(offsetSeconds: TimeInterval = 0) {
            self.offsetSeconds = offsetSeconds
        }

        var isTimeSynchronized: Bool { true }

        func currentTime() -> TimeInterval {
            return Date().timeIntervalSince1970 + offsetSeconds
        }

        var localTimeAdjustment: TimeInterval { offsetSeconds }
        var localTimeAdjustmentPrecision: TimeInterval { 0.05 }

        func synchronizeTime(callback: @escaping (Error?) -> Void, callbackQueue queue: DispatchQueue?) -> (any PowerAuthOperationTask)? {
            (queue ?? .main).async { callback(nil) }
            return nil
        }
    }

    /// Mock time service that reports NOT synchronized initially.
    /// Calling `synchronizeTime` succeeds and flips state to synchronized.
    private class DelayedSyncTimeService: NSObject, PowerAuthTimeSynchronizationService {
        func resetTimeSynchronization() {
            synchronized = false
        }

        let offsetSeconds: TimeInterval
        private var synchronized = false
        private(set) var syncCount = 0

        init(offsetSeconds: TimeInterval = 0) {
            self.offsetSeconds = offsetSeconds
        }

        var isTimeSynchronized: Bool { synchronized }

        func currentTime() -> TimeInterval {
            return Date().timeIntervalSince1970 + offsetSeconds
        }

        var localTimeAdjustment: TimeInterval { offsetSeconds }
        var localTimeAdjustmentPrecision: TimeInterval { 0.05 }

        func synchronizeTime(callback: @escaping (Error?) -> Void, callbackQueue queue: DispatchQueue?) -> (any PowerAuthOperationTask)? {
            syncCount += 1
            synchronized = true
            (queue ?? .main).async { callback(nil) }
            return nil
        }
    }

    /// Mock time service where synchronization always fails.
    private class FailingSyncTimeService: NSObject, PowerAuthTimeSynchronizationService {
        func resetTimeSynchronization() { }

        var isTimeSynchronized: Bool { false }

        func currentTime() -> TimeInterval {
            return Date().timeIntervalSince1970
        }

        var localTimeAdjustment: TimeInterval { 0 }
        var localTimeAdjustmentPrecision: TimeInterval { 0 }

        func synchronizeTime(callback: @escaping (Error?) -> Void, callbackQueue queue: DispatchQueue?) -> (any PowerAuthOperationTask)? {
            (queue ?? .main).async { callback(NSError(domain: "test", code: -1, userInfo: [NSLocalizedDescriptionKey: "Time sync unavailable"])) }
            return nil
        }
    }

    /// Mock time service that reports NOT synchronized and holds the synchronization result
    /// until `finishSynchronization()` is called.
    private class ManualSyncTimeService: NSObject, PowerAuthTimeSynchronizationService {
        func resetTimeSynchronization() { }

        /// Called (on a background thread) when the SDK starts the time synchronization.
        var onSynchronizationStarted: (() -> Void)?
        private var synchronized = false
        private var pendingCallback: (() -> Void)?

        var isTimeSynchronized: Bool { synchronized }

        func currentTime() -> TimeInterval {
            return Date().timeIntervalSince1970
        }

        var localTimeAdjustment: TimeInterval { 0 }
        var localTimeAdjustmentPrecision: TimeInterval { 0 }

        func synchronizeTime(callback: @escaping (Error?) -> Void, callbackQueue queue: DispatchQueue?) -> (any PowerAuthOperationTask)? {
            pendingCallback = { (queue ?? .main).async { callback(nil) } }
            onSynchronizationStarted?()
            return nil
        }

        /// Finishes the pending synchronization (if any) successfully.
        func finishSynchronization() {
            synchronized = true
            pendingCallback?()
            pendingCallback = nil
        }
    }

    // MARK: - Mock: WMTOperationsApi

    /// Mock API that captures authorize and reject requests and reports result on main thread.
    private class MockOperationApi: WMTOperationsApi {
        var lastAuthorizeData: WMTAuthorizationData?
        var lastRejectData: WMTRejectionData?
        var shouldSucceed = true
        /// When `true`, requests are never finished. Canceling the returned operation reports `.canceled`.
        var holdRequests = false
        private(set) var heldRequest: Operation?

        func authorize(data: WMTAuthorizationData, authentication: PowerAuthAuthentication, completion: @escaping (Result<Void, WMTError>) -> Void) -> Operation? {
            lastAuthorizeData = data
            return finish(completion)
        }

        func reject(data: WMTRejectionData, completion: @escaping (Result<Void, WMTError>) -> Void) -> Operation? {
            lastRejectData = data
            return finish(completion)
        }

        private func finish(_ completion: @escaping (Result<Void, WMTError>) -> Void) -> Operation? {
            guard holdRequests == false else {
                let request = WPNAsyncBlockOperation({ completion(.failure(WMTError(reason: .canceled))) }, executionBlock: { _, _ in })
                heldRequest = request
                return request
            }
            DispatchQueue.main.async {
                if self.shouldSucceed {
                    completion(.success(()))
                } else {
                    completion(.failure(WMTError(reason: .operations_failed)))
                }
            }
            return nil
        }
    }

    // MARK: - Mock: WMTOperation

    private struct TestOperation: WMTOperation {
        var id: String = "test-op-1"
        var data: String = "A1*A100CZK*ICZ2730300000001165254011*D20250101"
        var proximityCheck: WMTProximityCheck?
        var mobileTokenData: [String: Encodable]?
    }

    /// Customer-defined value that nests the recorder output.
    private struct NestedRecord: Encodable {
        let value: WMTAnyEncodable
    }

    // MARK: - Helpers

    private lazy var networking: WPNNetworkingService = {
        WPNNetworkingService(
            powerAuth: pa,
            config: WPNConfig(baseUrl: URL(string: pa.configuration.baseEndpointUrl)!),
            serviceName: "WMTProximityTests"
        )
    }()

    init() async throws {
        try await super.init()
    }

    private func createService(mockApi: MockOperationApi, timeService: NSObject & PowerAuthTimeSynchronizationService) -> WMTOperations {
        return WMTOperations(networking: networking, operationApi: mockApi, timeService: timeService)
    }

    private typealias Visit = WMTPreApprovalScreensRecorder.Visit

    private static let recorderKey = "preApprovalScreens"
    private static let riskScore = 0.82

    /// Creates an operation with recorder output stored as a top-level `mobileTokenData` entry next to a generic entry.
    private func operationWithRecorder(proximityCheck: WMTProximityCheck? = nil) -> TestOperation {
        let recorder = WMTPreApprovalScreensRecorder()
        recorder.begin("intro")
        recorder.end("intro", action: .continue)
        recorder.begin("qr")
        recorder.end("qr", action: .scan)

        var operation = TestOperation()
        operation.proximityCheck = proximityCheck
        operation.mobileTokenData = WMTMobileTokenData.Builder(initialData: ["riskScore": Self.riskScore])
            .put(recorder)
            .build()
        return operation
    }

    /// Visits with device-time timestamps stored in the operation.
    private func recordedVisits(_ operation: TestOperation) throws -> [Visit] {
        let visits = try #require(operation.mobileTokenData?[Self.recorderKey] as? WMTPreApprovalScreensRecorder.Visits)
        return visits.visits
    }

    /// Visits that were sent to the server.
    private func sentVisits(_ mobileTokenData: [String: WMTAnyEncodable]?) throws -> [Visit] {
        let value = try #require(mobileTokenData?[Self.recorderKey]?.original, "Recorder data should be sent")
        return try #require(value as? [Visit], "Recorder data should be sent as adjusted visits")
    }

    private func shifted(_ visits: [Visit], by offset: TimeInterval) -> [Visit] {
        return visits.map { visit in
            var shifted = visit
            shifted.timestampOpened = visit.timestampOpened.addingTimeInterval(offset)
            shifted.timestampClosed = visit.timestampClosed?.addingTimeInterval(offset)
            return shifted
        }
    }

    private func expectRiskScoreUnchanged(_ mobileTokenData: [String: WMTAnyEncodable]?) {
        #expect(mobileTokenData?["riskScore"]?.original as? Double == Self.riskScore, "Other mobileTokenData entries should be sent unchanged")
    }

    /// Tolerance for floating point rounding when comparing timestamps.
    private static let timeTolerance: TimeInterval = 0.01

    /// Expects `date` to be a device time captured between `start` and `end`, shifted by `offset`.
    ///
    /// The time is bracketed by values captured around the call instead of being compared
    /// with the current time afterwards, so the check doesn't depend on how fast the test runs.
    private func expectTime(
        _ date: Date,
        between start: Date,
        and end: Date,
        shiftedBy offset: TimeInterval,
        _ comment: Comment,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let deviceTime = date.timeIntervalSince1970 - offset
        let lowerBound = start.timeIntervalSince1970 - Self.timeTolerance
        let upperBound = end.timeIntervalSince1970 + Self.timeTolerance
        #expect(deviceTime >= lowerBound && deviceTime <= upperBound, comment, sourceLocation: sourceLocation)
    }

    private func expectTimeSyncFailure(_ error: Error) {
        #expect((error as? WMTError)?.reason == .operations_failed)
        #expect((error as? WMTError)?.nestedError != nil, "Original sync error should be wrapped")
    }

    /// Operation returned by the service and results delivered to its completion.
    private final class CancellationProbe {
        var operation: Operation?
        var results: [Result<Void, WMTError>] = []
    }

    /// Starts a request that requires time synchronization and cancels the returned operation either
    /// while the time is being synchronized, or right after the request is sent.
    /// Returns all results delivered to the completion.
    @MainActor
    private func startAndCancel(
        afterTimeSync: Bool,
        timeService: ManualSyncTimeService,
        start: (_ completion: @escaping (Result<Void, WMTError>) -> Void) -> Operation?
    ) async -> [Result<Void, WMTError>] {
        let probe = CancellationProbe()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            timeService.onSynchronizationStarted = {
                DispatchQueue.main.async {
                    if afterTimeSync {
                        // The sync callback (which sends the request) is dispatched before the cancellation.
                        timeService.finishSynchronization()
                        DispatchQueue.main.async { probe.operation?.cancel() }
                    } else {
                        probe.operation?.cancel()
                    }
                }
            }
            probe.operation = start { result in
                probe.results.append(result)
                if probe.results.count == 1 {
                    continuation.resume()
                }
            }
        }
        // Finish the pending synchronization (if any) and let late callbacks run.
        timeService.finishSynchronization()
        await withCheckedContinuation { continuation in DispatchQueue.main.async { continuation.resume() } }
        return probe.results
    }

    private func expectCanceledOnce(_ results: [Result<Void, WMTError>]) {
        #expect(results.count == 1, "Completion should be called exactly once")
        guard case .failure(let error) = results.first else {
            Issue.record("Should fail with the canceled error")
            return
        }
        #expect(error.reason == .canceled)
    }

    // MARK: - Tests

    @Test
    func authorizeWithoutProximityCheck() async throws {
        let mockApi = MockOperationApi()
        let service = createService(mockApi: mockApi, timeService: SynchronizedTimeService())

        let operation = TestOperation()
        try await service.authorize(operation: operation, with: .possession())

        #expect(mockApi.lastAuthorizeData != nil, "Request should be captured")
        #expect(mockApi.lastAuthorizeData?.proximityCheck == nil, "proximityCheck should be nil")
    }

    @Test
    func authorizeWithProximityCheckTimeSynchronized() async throws {
        let offsetSeconds: TimeInterval = 5 * 60
        let mockApi = MockOperationApi()
        let service = createService(mockApi: mockApi, timeService: SynchronizedTimeService(offsetSeconds: offsetSeconds))

        let start = Date()
        var operation = TestOperation()
        operation.proximityCheck = WMTProximityCheck(totp: "123456", type: .qrCode)

        try await service.authorize(operation: operation, with: .possession())
        let end = Date()

        let pcData = try #require(mockApi.lastAuthorizeData?.proximityCheck)
        #expect(pcData.otp == "123456")
        #expect(pcData.type == .qrCode)

        expectTime(pcData.timestampReceived, between: start, and: end, shiftedBy: offsetSeconds, "timestampReceived should be ~5min ahead")
        expectTime(pcData.timestampSent, between: start, and: end, shiftedBy: offsetSeconds, "timestampSent should be ~5min ahead")
    }

    @Test
    func authorizeWithProximityCheckTimeNotSynchronizedThenSyncs() async throws {
        let offsetSeconds: TimeInterval = -3 * 60
        let mockApi = MockOperationApi()
        let service = createService(mockApi: mockApi, timeService: DelayedSyncTimeService(offsetSeconds: offsetSeconds))

        let start = Date()
        var operation = TestOperation()
        operation.proximityCheck = WMTProximityCheck(totp: "654321", type: .deeplink)

        try await service.authorize(operation: operation, with: .possession())
        let end = Date()

        let pcData = try #require(mockApi.lastAuthorizeData?.proximityCheck)
        #expect(pcData.otp == "654321")
        #expect(pcData.type == .deeplink)

        expectTime(pcData.timestampReceived, between: start, and: end, shiftedBy: offsetSeconds, "timestampReceived should be ~3min behind")
    }

    @Test
    func authorizeWithProximityCheckTimeSyncFails() async throws {
        let mockApi = MockOperationApi()
        let service = createService(mockApi: mockApi, timeService: FailingSyncTimeService())

        var operation = TestOperation()
        operation.proximityCheck = WMTProximityCheck(totp: "111111", type: .qrCode)

        do {
            try await service.authorize(operation: operation, with: .possession())
            Issue.record("Should fail when time sync fails")
        } catch {
            #expect(error is WMTError)
        }
        #expect(mockApi.lastAuthorizeData == nil, "API should not be called when sync fails")
    }

    @Test
    func timestampAdjustmentWithZeroOffset() async throws {
        let mockApi = MockOperationApi()
        let service = createService(mockApi: mockApi, timeService: SynchronizedTimeService(offsetSeconds: 0))

        let start = Date()
        var operation = TestOperation()
        operation.proximityCheck = WMTProximityCheck(totp: "000000", type: .qrCode)

        try await service.authorize(operation: operation, with: .possession())
        let end = Date()

        let pcData = try #require(mockApi.lastAuthorizeData?.proximityCheck)
        expectTime(pcData.timestampReceived, between: start, and: end, shiftedBy: 0, "timestampReceived should be device time")
        expectTime(pcData.timestampSent, between: start, and: end, shiftedBy: 0, "timestampSent should be device time")
    }

    @Test
    func timestampAdjustmentWithLargePositiveOffset() async throws {
        let oneHour: TimeInterval = 60 * 60
        let mockApi = MockOperationApi()
        let service = createService(mockApi: mockApi, timeService: SynchronizedTimeService(offsetSeconds: oneHour))

        let start = Date()
        var operation = TestOperation()
        operation.proximityCheck = WMTProximityCheck(totp: "999999", type: .deeplink)

        try await service.authorize(operation: operation, with: .possession())
        let end = Date()

        let pcData = try #require(mockApi.lastAuthorizeData?.proximityCheck)
        expectTime(pcData.timestampReceived, between: start, and: end, shiftedBy: oneHour, "timestampReceived should be ~1h ahead")
        expectTime(pcData.timestampSent, between: start, and: end, shiftedBy: oneHour, "timestampSent should be ~1h ahead")
    }

    @Test
    func timestampReceivedPreservesOriginalTimeDelta() async throws {
        let offsetSeconds: TimeInterval = 10
        let mockApi = MockOperationApi()
        let service = createService(mockApi: mockApi, timeService: SynchronizedTimeService(offsetSeconds: offsetSeconds))

        var operation = TestOperation()
        // Create proximity check — captures Date() as timestampReceived
        let createStart = Date()
        let pc = WMTProximityCheck(totp: "abc123", type: .qrCode)
        let createEnd = Date()
        operation.proximityCheck = pc

        // Simulate time passing between QR scan and authorize call
        try await Task.sleep(nanoseconds: 5_000_000_000)

        let authorizeStart = Date()
        try await service.authorize(operation: operation, with: .possession())
        let authorizeEnd = Date()

        let pcData = try #require(mockApi.lastAuthorizeData?.proximityCheck)

        // Both timestamps should be adjusted by the same offset, so the delta between them
        // is the time that passed between the QR scan and the authorize call (at least the sleep duration)
        expectTime(pcData.timestampReceived, between: createStart, and: createEnd, shiftedBy: offsetSeconds, "timestampReceived should be the scan time adjusted by the offset")
        expectTime(pcData.timestampSent, between: authorizeStart, and: authorizeEnd, shiftedBy: offsetSeconds, "timestampSent should be the authorize time adjusted by the offset")
        let delta = pcData.timestampSent.timeIntervalSince(pcData.timestampReceived)
        #expect(delta >= 5 - Self.timeTolerance, "Delta between sent and received should be at least 5s, got \(delta)s")
    }

    // MARK: - Tests: mobileTokenData alignment (authorize)

    @Test
    func authorizeAlignsRecorderTimestampsWhenTimeSynchronized() async throws {
        let offsetSeconds: TimeInterval = 5 * 60
        let mockApi = MockOperationApi()
        let service = createService(mockApi: mockApi, timeService: SynchronizedTimeService(offsetSeconds: offsetSeconds))

        let operation = operationWithRecorder()
        try await service.authorize(operation: operation, with: .possession())

        let sent = try sentVisits(mockApi.lastAuthorizeData?.mobileTokenData)
        #expect(sent == shifted(try recordedVisits(operation), by: offsetSeconds))
        expectRiskScoreUnchanged(mockApi.lastAuthorizeData?.mobileTokenData)
        #expect(mockApi.lastAuthorizeData?.proximityCheck == nil)
    }

    @Test
    func authorizeSynchronizesTimeBeforeAligningRecorder() async throws {
        let offsetSeconds: TimeInterval = -3 * 60
        let mockApi = MockOperationApi()
        let timeService = DelayedSyncTimeService(offsetSeconds: offsetSeconds)
        let service = createService(mockApi: mockApi, timeService: timeService)

        let operation = operationWithRecorder()
        try await service.authorize(operation: operation, with: .possession())

        #expect(timeService.syncCount == 1, "Time should be synchronized before authorize")
        let sent = try sentVisits(mockApi.lastAuthorizeData?.mobileTokenData)
        #expect(sent == shifted(try recordedVisits(operation), by: offsetSeconds))
        expectRiskScoreUnchanged(mockApi.lastAuthorizeData?.mobileTokenData)
    }

    @Test
    func authorizeWithRecorderTimeSyncFails() async throws {
        let mockApi = MockOperationApi()
        let service = createService(mockApi: mockApi, timeService: FailingSyncTimeService())

        do {
            try await service.authorize(operation: operationWithRecorder(), with: .possession())
            Issue.record("Should fail when time sync fails")
        } catch {
            expectTimeSyncFailure(error)
        }
        #expect(mockApi.lastAuthorizeData == nil, "API should not be called when sync fails")
    }

    @Test
    func authorizeWithoutTimeSensitiveDataDoesNotSync() async throws {
        let mockApi = MockOperationApi()
        let timeService = DelayedSyncTimeService(offsetSeconds: 60)
        let service = createService(mockApi: mockApi, timeService: timeService)

        var operation = TestOperation()
        operation.mobileTokenData = ["riskScore": Self.riskScore]
        try await service.authorize(operation: operation, with: .possession())

        #expect(timeService.syncCount == 0, "Time should not be synchronized without time-sensitive data")
        expectRiskScoreUnchanged(mockApi.lastAuthorizeData?.mobileTokenData)
    }

    @Test
    func authorizeWithProximityCheckAndRecorderSyncsOnce() async throws {
        let offsetSeconds: TimeInterval = 2 * 60
        let mockApi = MockOperationApi()
        let timeService = DelayedSyncTimeService(offsetSeconds: offsetSeconds)
        let service = createService(mockApi: mockApi, timeService: timeService)

        let proximityCheck = WMTProximityCheck(totp: "123456", type: .qrCode)
        let operation = operationWithRecorder(proximityCheck: proximityCheck)
        try await service.authorize(operation: operation, with: .possession())

        #expect(timeService.syncCount == 1, "Time should be synchronized only once")
        let pcData = try #require(mockApi.lastAuthorizeData?.proximityCheck)
        #expect(pcData.timestampReceived == proximityCheck.timestampReceived.addingTimeInterval(offsetSeconds))
        let sent = try sentVisits(mockApi.lastAuthorizeData?.mobileTokenData)
        #expect(sent == shifted(try recordedVisits(operation), by: offsetSeconds))
    }

    @Test
    func authorizeDoesNotAlignNestedRecorderData() async throws {
        let mockApi = MockOperationApi()
        let timeService = DelayedSyncTimeService(offsetSeconds: 5 * 60)
        let service = createService(mockApi: mockApi, timeService: timeService)

        let recorder = WMTPreApprovalScreensRecorder()
        recorder.begin("intro")
        recorder.end("intro", action: .continue)
        let recorded = try #require(recorder.build() as? WMTPreApprovalScreensRecorder.Visits)

        var operation = TestOperation()
        operation.mobileTokenData = ["nested": NestedRecord(value: WMTAnyEncodable(recorded))]
        try await service.authorize(operation: operation, with: .possession())

        #expect(timeService.syncCount == 0, "Nested recorder data is not detected as time-sensitive")
        let nested = try #require(mockApi.lastAuthorizeData?.mobileTokenData?["nested"]?.original as? NestedRecord)
        let sent = try #require(nested.value.original as? WMTPreApprovalScreensRecorder.Visits)
        #expect(sent.visits == recorded.visits, "Nested recorder data should be sent with device time")
    }

    @Test
    func authorizeRetryAfterFailureDoesNotAdjustTwice() async throws {
        let offsetSeconds: TimeInterval = 5 * 60
        let mockApi = MockOperationApi()
        let service = createService(mockApi: mockApi, timeService: SynchronizedTimeService(offsetSeconds: offsetSeconds))

        let proximityCheck = WMTProximityCheck(totp: "123456", type: .deeplink)
        let originalReceived = proximityCheck.timestampReceived
        let operation = operationWithRecorder(proximityCheck: proximityCheck)
        let recorded = try recordedVisits(operation)

        mockApi.shouldSucceed = false
        await #expect(throws: WMTError.self) {
            try await service.authorize(operation: operation, with: .possession())
        }

        mockApi.shouldSucceed = true
        try await service.authorize(operation: operation, with: .possession())

        let pcData = try #require(mockApi.lastAuthorizeData?.proximityCheck)
        #expect(pcData.timestampReceived == originalReceived.addingTimeInterval(offsetSeconds), "Proximity check should be adjusted only once")
        #expect(proximityCheck.timestampReceived == originalReceived, "Operation's proximity check must not be modified")
        #expect(try sentVisits(mockApi.lastAuthorizeData?.mobileTokenData) == shifted(recorded, by: offsetSeconds), "Recorder data should be adjusted only once")
        #expect(try recordedVisits(operation) == recorded, "Operation's mobileTokenData must not be modified")
    }

    // MARK: - Tests: mobileTokenData alignment (reject)

    @Test
    func rejectAlignsRecorderTimestampsWhenTimeSynchronized() async throws {
        let offsetSeconds: TimeInterval = 5 * 60
        let mockApi = MockOperationApi()
        let service = createService(mockApi: mockApi, timeService: SynchronizedTimeService(offsetSeconds: offsetSeconds))

        let operation = operationWithRecorder()
        try await service.reject(operation: operation, with: .unexpectedOperation)

        let sent = try sentVisits(mockApi.lastRejectData?.mobileTokenData)
        #expect(sent == shifted(try recordedVisits(operation), by: offsetSeconds))
        expectRiskScoreUnchanged(mockApi.lastRejectData?.mobileTokenData)
        #expect(mockApi.lastRejectData?.reason == WMTRejectionReason.unexpectedOperation.serialized)
    }

    @Test
    func rejectSynchronizesTimeBeforeAligningRecorder() async throws {
        let offsetSeconds: TimeInterval = -3 * 60
        let mockApi = MockOperationApi()
        let timeService = DelayedSyncTimeService(offsetSeconds: offsetSeconds)
        let service = createService(mockApi: mockApi, timeService: timeService)

        let operation = operationWithRecorder()
        try await service.reject(operation: operation, with: .unexpectedOperation)

        #expect(timeService.syncCount == 1, "Time should be synchronized before reject")
        let sent = try sentVisits(mockApi.lastRejectData?.mobileTokenData)
        #expect(sent == shifted(try recordedVisits(operation), by: offsetSeconds))
    }

    @Test
    func rejectWithRecorderTimeSyncFails() async throws {
        let mockApi = MockOperationApi()
        let service = createService(mockApi: mockApi, timeService: FailingSyncTimeService())

        do {
            try await service.reject(operation: operationWithRecorder(), with: .unexpectedOperation)
            Issue.record("Should fail when time sync fails")
        } catch {
            expectTimeSyncFailure(error)
        }
        #expect(mockApi.lastRejectData == nil, "API should not be called when sync fails")
    }

    @Test
    func rejectWithoutTimeSensitiveDataDoesNotSync() async throws {
        let mockApi = MockOperationApi()
        let timeService = DelayedSyncTimeService(offsetSeconds: 60)
        let service = createService(mockApi: mockApi, timeService: timeService)

        var operation = TestOperation()
        operation.mobileTokenData = ["riskScore": Self.riskScore]
        try await service.reject(operation: operation, with: .unexpectedOperation)

        #expect(timeService.syncCount == 0, "Time should not be synchronized without time-sensitive data")
        #expect(mockApi.lastRejectData != nil, "Request should be captured")
        expectRiskScoreUnchanged(mockApi.lastRejectData?.mobileTokenData)
    }

    // MARK: - Cancellation

    @Test
    @MainActor
    func authorizeCanceledDuringTimeSyncIsNotSent() async throws {
        let mockApi = MockOperationApi()
        let timeService = ManualSyncTimeService()
        let service = createService(mockApi: mockApi, timeService: timeService)
        let operation = operationWithRecorder()

        let results = await startAndCancel(afterTimeSync: false, timeService: timeService) { completion in
            service.authorize(operation: operation, with: .possession(), completion: completion)
        }

        expectCanceledOnce(results)
        #expect(mockApi.lastAuthorizeData == nil, "API should not be called when canceled during time sync")
    }

    @Test
    @MainActor
    func rejectCanceledDuringTimeSyncIsNotSent() async throws {
        let mockApi = MockOperationApi()
        let timeService = ManualSyncTimeService()
        let service = createService(mockApi: mockApi, timeService: timeService)
        let operation = operationWithRecorder()

        let results = await startAndCancel(afterTimeSync: false, timeService: timeService) { completion in
            service.reject(operation: operation, with: .unexpectedOperation, completion: completion)
        }

        expectCanceledOnce(results)
        #expect(mockApi.lastRejectData == nil, "API should not be called when canceled during time sync")
    }

    @Test
    @MainActor
    func rejectCanceledAfterTimeSyncCancelsRequest() async throws {
        let mockApi = MockOperationApi()
        mockApi.holdRequests = true
        let timeService = ManualSyncTimeService()
        let service = createService(mockApi: mockApi, timeService: timeService)
        let operation = operationWithRecorder()

        let results = await startAndCancel(afterTimeSync: true, timeService: timeService) { completion in
            service.reject(operation: operation, with: .unexpectedOperation, completion: completion)
        }

        expectCanceledOnce(results)
        #expect(mockApi.lastRejectData != nil, "Request should be sent after time sync")
        #expect(mockApi.heldRequest?.isCancelled == true, "Sent request should be canceled")
    }
}
