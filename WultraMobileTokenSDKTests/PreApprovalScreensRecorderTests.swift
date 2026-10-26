//
// Copyright 2026 Wultra s.r.o.
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
@testable import WultraMobileTokenSDK

/// Unit tests for `WMTPreApprovalScreensRecorder` covering device-time recording,
/// server time adjustment, and the serialized output.
struct PreApprovalScreensRecorderTests {

    private typealias Visit = WMTPreApprovalScreensRecorder.Visit
    private typealias Visits = WMTPreApprovalScreensRecorder.Visits

    private func buildVisits(_ recorder: WMTPreApprovalScreensRecorder) throws -> Visits {
        return try #require(recorder.build() as? Visits, "build() should return server-time-adjustable visits")
    }

    @Test
    func recorderUsesDeviceTime() throws {
        let recorder = WMTPreApprovalScreensRecorder()
        let before = Date()
        recorder.begin("intro")
        recorder.end("intro", action: .continue)
        let after = Date()

        let visit = try #require(try buildVisits(recorder).visits.first)
        #expect(visit.screen == "intro")
        #expect(visit.action == "CONTINUE")
        #expect(visit.timestampOpened >= before && visit.timestampOpened <= after)
        let closed = try #require(visit.timestampClosed)
        #expect(closed >= visit.timestampOpened && closed <= after)
    }

    @Test(arguments: [TimeInterval(5 * 60), TimeInterval(-3 * 60), TimeInterval(0)])
    func adjustedShiftsTimestampsByOffset(offset: TimeInterval) throws {
        let recorder = WMTPreApprovalScreensRecorder()
        recorder.begin("intro")
        recorder.end("intro", action: .continue)
        recorder.begin("qr")
        recorder.begin("summary")

        let visits = try buildVisits(recorder)
        let original = visits.visits
        let adjusted = try #require(visits.adjusted(by: offset) as? [Visit])

        #expect(adjusted.count == original.count)
        for (adjustedVisit, originalVisit) in zip(adjusted, original) {
            #expect(adjustedVisit.screen == originalVisit.screen)
            #expect(adjustedVisit.action == originalVisit.action)
            #expect(adjustedVisit.timestampOpened == originalVisit.timestampOpened.addingTimeInterval(offset))
            #expect(adjustedVisit.timestampClosed == originalVisit.timestampClosed?.addingTimeInterval(offset))
        }
        #expect(visits.visits == original, "Adjusting must not change the original data")
    }

    @Test
    func adjustedVisitsAreNotAdjustableAgain() throws {
        let recorder = WMTPreApprovalScreensRecorder()
        recorder.begin("intro")
        recorder.end("intro", action: .close)

        let adjusted = try buildVisits(recorder).adjusted(by: 60)
        #expect(!(adjusted is WMTServerTimeAdjustable), "Adjusted value must not be adjusted twice")
    }

    @Test
    func repeatedBuildReturnsEqualResults() throws {
        let recorder = WMTPreApprovalScreensRecorder()
        recorder.begin("intro")
        recorder.end("intro", action: .continue)
        recorder.begin("qr")
        recorder.end("qr", action: .scan)

        let first = try buildVisits(recorder)
        let second = try buildVisits(recorder)
        #expect(first.visits == second.visits)
        #expect(first.visits.count == 2)
    }

    @Test
    func buildClosesOpenVisit() throws {
        let recorder = WMTPreApprovalScreensRecorder()
        recorder.begin("intro")

        let visits = try buildVisits(recorder).visits
        let visit = try #require(visits.first)
        #expect(visits.count == 1)
        #expect(visit.screen == "intro")
        #expect(visit.timestampClosed != nil, "Open visit should be closed by build()")
        #expect(visit.action == nil, "Visit closed by build() has no action")
    }

    @Test
    func outputSerializesAsArrayOfUtcInstants() throws {
        let recorder = WMTPreApprovalScreensRecorder()
        recorder.begin("intro")
        recorder.end("intro", action: .custom("CUSTOM_ACTION"))

        let visits = try buildVisits(recorder)
        let visit = try #require(visits.visits.first)

        // Same date encoding strategy as the networking layer
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let json = try encoder.encode(WMTAnyEncodable(recorder.build()))
        let array = try #require(try JSONSerialization.jsonObject(with: json) as? [[String: Any]], "Output should be a JSON array")
        let object = try #require(array.first)

        #expect(array.count == 1)
        #expect(object["screen"] as? String == "intro")
        #expect(object["action"] as? String == "CUSTOM_ACTION")

        let opened = try #require(object["timestampOpened"] as? String)
        let closed = try #require(object["timestampClosed"] as? String)
        #expect(opened.hasSuffix("Z"))
        #expect(closed.hasSuffix("Z"))

        let formatter = ISO8601DateFormatter()
        let openedDate = try #require(formatter.date(from: opened))
        let closedDate = try #require(formatter.date(from: closed))
        let visitClosed = try #require(visit.timestampClosed)
        #expect(abs(openedDate.timeIntervalSince(visit.timestampOpened)) < 1)
        #expect(abs(closedDate.timeIntervalSince(visitClosed)) < 1)
    }
}
