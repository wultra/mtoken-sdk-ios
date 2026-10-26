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

/// Records user navigation through Pre-approval screens.
/// Each “visit” captures an opening timestamp and, when closed, a closing
/// timestamp and the action that ended the visit.
///
/// Timestamps are captured with the device time. When the recorded data is sent as a top-level
/// `mobileTokenData` entry with `WMTOperations.authorize(operation:with:completion:)` or
/// `WMTOperations.reject(operation:with:completion:)`, the SDK aligns them to server time,
/// synchronizing the time with the server first if needed.
public final class WMTPreApprovalScreensRecorder: WMTMobileTokenDataRecord {

    /// Top-level key under which this record is stored in `mobileTokenData`.
    public var key: String { "preApprovalScreens" }

    /// Extensible action set. Stored as its string form (`name`) in the payload.
    public enum ScreenAction: Encodable {
        case `continue`
        case back
        case close
        case reject
        case scan
        case custom(String)

        var name: String {
            switch self {
            case .continue: return "CONTINUE"
            case .back:     return "BACK"
            case .close:    return "CLOSE"
            case .reject:   return "REJECT"
            case .scan:     return "SCAN"
            case .custom(let action): return action
            }
        }
    }

    /// One screen visit within the Pre-approval flow.
    struct Visit: Encodable, Equatable {
        let screen: String
        var timestampOpened: Date
        var timestampClosed: Date?
        var action: String?
    }

    /// Snapshot of visits with device-time timestamps, encoded as a plain array of visits.
    /// Aligned to server time by `WMTOperations` before it's sent.
    struct Visits: Encodable, WMTServerTimeAdjustable {
        let visits: [Visit]

        func encode(to encoder: Encoder) throws {
            try visits.encode(to: encoder)
        }

        func adjusted(by localTimeAdjustment: TimeInterval) -> Encodable {
            return visits.map { visit in
                var adjusted = visit
                adjusted.timestampOpened = visit.timestampOpened.addingTimeInterval(localTimeAdjustment)
                adjusted.timestampClosed = visit.timestampClosed?.addingTimeInterval(localTimeAdjustment)
                return adjusted
            }
        }
    }

    /// Currently open visit (if any).
    private var openVisit: Visit?

    /// Finalized visits accumulated by the recorder.
    private var visits: [Visit] = []

    /// Synchronization primitive that protects recorder state.
    private let lock = WMTLock()

    /// Creates a new recorder.
    ///
    /// Timestamps are captured with the device time and aligned to server time
    /// by `WMTOperations` when the operation is authorized or rejected.
    public init() {}

    /// Creates a new recorder.
    ///
    /// The recorder captures device time and the SDK aligns it to server time during
    /// operation authorization or rejection, so the `PowerAuthSDK` instance is no longer needed.
    ///
    /// - Parameter powerAuthSDK: Instance of `PowerAuthSDK` (no longer used).
    @available(*, deprecated, renamed: "init()", message: "PowerAuthSDK is no longer needed. The SDK aligns recorded timestamps to server time during authorize and reject.")
    public convenience init(powerAuthSDK: PowerAuthSDK) {
        self.init()
    }

    /// Opens a new visit for `id`. If a different visit is already open,
    /// it is appended as-is (without `timestampClosed` / `action`).
    @discardableResult
    public func begin(_ id: String) -> Self {
        lock.synchronized {
            guard !id.isEmpty else { return }
            if let live = openVisit {
                if live.screen == id { return }
                visits.append(live)
            }
            openVisit = Visit(screen: id, timestampOpened: now(), timestampClosed: nil, action: nil)
        }
        return self
    }

    /// Closes the current visit (if its id matches) and records `action`.
    @discardableResult
    public func end(_ id: String, action: ScreenAction) -> Self {
        lock.synchronized {
            // An open visit matches this id → close & append
            if var live = openVisit, live.screen == id {
                live.timestampClosed = now()
                live.action = action.name
                visits.append(live)
                openVisit = nil
            // No openVisit, but the last recorded visit with same id is still unfinished
            } else if let lastIdx = visits.indices.last, visits[lastIdx].screen == id,
               visits[lastIdx].timestampClosed == nil, visits[lastIdx].action == nil {
                var v = visits[lastIdx]
                v.timestampClosed = now()
                v.action = action.name
                visits[lastIdx] = v
            }
            return self
        }
    }
    
    /// Produces the value representation for `mobileTokenData`.
    /// Returns an array of visit objects with device-time timestamps and actions.
    ///
    /// The timestamps are aligned to server time by the SDK when the value is sent
    /// as a top-level `mobileTokenData` entry during operation authorization or rejection.
    public func build() -> Encodable {
        lock.synchronized {
            // If a visit is still open, close it now (no action)
            if var live = openVisit {
                WMTLogger.warning("WMTPreApprovalScreensRecorder is building unended visit for screen '\(live.screen)', ending it automatically with no action")
                live.timestampClosed = now()
                visits.append(live)
                openVisit = nil
            }
            
            return Visits(visits: visits)
        }
    }

    /// Clears all collected visits, allowing the recorder to start fresh.
    public func reset() {
        lock.synchronized {
            openVisit = nil
            visits.removeAll()
        }
    }
    
    // MARK: Time helper

    /// Current device time. Aligned to server time by the SDK before it's sent.
    private func now() -> Date {
        return Date()
    }
}
