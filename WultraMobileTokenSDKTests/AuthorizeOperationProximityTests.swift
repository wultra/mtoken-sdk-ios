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

/// Integration tests for `WMTOperations.authorize(operation:with:)` covering all proximity check branches:
/// - No proximity check → authorize directly (no timestamp adjustment)
/// - Proximity check + time already synchronized → adjust timestamps, then authorize
/// - Proximity check + time NOT synchronized → synchronize first, adjust, then authorize
/// - Proximity check + time synchronization FAILS → callback with failure
/// - Timestamp adjustment logic (zero offset, large offset, custom timestampReceived)
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

    // MARK: - Mock: WMTOperationsApi

    /// Mock API that captures authorize requests and reports result on main thread.
    private class MockOperationApi: WMTOperationsApi {
        var lastAuthorizeData: WMTAuthorizationData?
        var shouldSucceed = true

        func authorize(data: WMTAuthorizationData, authentication: PowerAuthAuthentication, completion: @escaping (Result<Void, WMTError>) -> Void) -> Operation? {
            lastAuthorizeData = data
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

        var operation = TestOperation()
        operation.proximityCheck = WMTProximityCheck(totp: "123456", type: .qrCode)

        try await service.authorize(operation: operation, with: .possession())

        let pcData = try #require(mockApi.lastAuthorizeData?.proximityCheck)
        #expect(pcData.otp == "123456")
        #expect(pcData.type == .qrCode)

        let now = Date().timeIntervalSince1970
        #expect(abs(pcData.timestampReceived.timeIntervalSince1970 - (now + offsetSeconds)) < 2, "timestampReceived should be ~5min ahead")
        #expect(abs(pcData.timestampSent.timeIntervalSince1970 - (now + offsetSeconds)) < 2, "timestampSent should be ~5min ahead")
    }

    @Test
    func authorizeWithProximityCheckTimeNotSynchronizedThenSyncs() async throws {
        let offsetSeconds: TimeInterval = -3 * 60
        let mockApi = MockOperationApi()
        let service = createService(mockApi: mockApi, timeService: DelayedSyncTimeService(offsetSeconds: offsetSeconds))

        var operation = TestOperation()
        operation.proximityCheck = WMTProximityCheck(totp: "654321", type: .deeplink)

        try await service.authorize(operation: operation, with: .possession())

        let pcData = try #require(mockApi.lastAuthorizeData?.proximityCheck)
        #expect(pcData.otp == "654321")
        #expect(pcData.type == .deeplink)

        let now = Date().timeIntervalSince1970
        #expect(abs(pcData.timestampReceived.timeIntervalSince1970 - (now + offsetSeconds)) < 2, "timestampReceived should be ~3min behind")
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

        var operation = TestOperation()
        operation.proximityCheck = WMTProximityCheck(totp: "000000", type: .qrCode)

        try await service.authorize(operation: operation, with: .possession())

        let pcData = try #require(mockApi.lastAuthorizeData?.proximityCheck)
        let now = Date().timeIntervalSince1970
        #expect(abs(pcData.timestampReceived.timeIntervalSince1970 - now) < 2, "timestampReceived should be close to device time")
        #expect(abs(pcData.timestampSent.timeIntervalSince1970 - now) < 2, "timestampSent should be close to device time")
    }

    @Test
    func timestampAdjustmentWithLargePositiveOffset() async throws {
        let oneHour: TimeInterval = 60 * 60
        let mockApi = MockOperationApi()
        let service = createService(mockApi: mockApi, timeService: SynchronizedTimeService(offsetSeconds: oneHour))

        var operation = TestOperation()
        operation.proximityCheck = WMTProximityCheck(totp: "999999", type: .deeplink)

        try await service.authorize(operation: operation, with: .possession())

        let pcData = try #require(mockApi.lastAuthorizeData?.proximityCheck)
        let now = Date().timeIntervalSince1970
        #expect(abs(pcData.timestampReceived.timeIntervalSince1970 - (now + oneHour)) < 2, "timestampReceived should be ~1h ahead")
        #expect(abs(pcData.timestampSent.timeIntervalSince1970 - (now + oneHour)) < 2, "timestampSent should be ~1h ahead")
    }

    @Test
    func timestampReceivedPreservesOriginalTimeDelta() async throws {
        let offsetSeconds: TimeInterval = 10
        let mockApi = MockOperationApi()
        let service = createService(mockApi: mockApi, timeService: SynchronizedTimeService(offsetSeconds: offsetSeconds))

        var operation = TestOperation()
        // Create proximity check — captures Date() as timestampReceived
        let pc = WMTProximityCheck(totp: "abc123", type: .qrCode)
        operation.proximityCheck = pc

        // Simulate time passing between QR scan and authorize call
        try await Task.sleep(nanoseconds: 5_000_000_000)

        try await service.authorize(operation: operation, with: .possession())

        let pcData = try #require(mockApi.lastAuthorizeData?.proximityCheck)

        let receivedTs = pcData.timestampReceived.timeIntervalSince1970
        let sentTs = pcData.timestampSent.timeIntervalSince1970

        // Both timestamps should be adjusted by the same offset, so the delta between them
        // should be ~5 seconds (the sleep duration)
        let delta = sentTs - receivedTs
        #expect(delta > 3 && delta < 7, "Delta between sent and received should be ~5s, got \(delta)s")
    }
}
