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
/// timestamp and the action that ended the visit. Timestamps use
/// `PowerAuthSDK.timeSynchronizationService` when available.
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
    private struct Visit: Encodable {
        let screen: String
        let timestampOpened: Date
        var timestampClosed: Date?
        var action: String?
    }

    /// Time source (used only for synchronized timestamps).
    private let powerAuthSDK: PowerAuthSDK

    /// Currently open visit (if any).
    private var openVisit: Visit?

    /// Finalized visits accumulated by the recorder.
    private var visits: [Visit] = []

    /// Synchronization primitive that protects recorder state.
    private let lock = WMTLock()

    /// Creates a new recorder. The provided `PowerAuthSDK` is used
    /// to obtain synchronized time for timestamps when available.
    public init(powerAuthSDK: PowerAuthSDK) {
        self.powerAuthSDK = powerAuthSDK
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
    /// Returns an array of visit objects with timestamps and actions.
    public func build() -> Encodable {
        lock.synchronized {
            // If a visit is still open, close it now (no action)
            if var live = openVisit {
                WMTLogger.warning("WMTPreApprovalScreensRecorder is building unended visit for screen '\(live.screen)', ending it automatically with no action")
                live.timestampClosed = now()
                visits.append(live)
                openVisit = nil
            }
            
            return visits
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

    /// Current time using `PowerAuthSDK` time synchronization when available.
    private func now() -> Date {
        let timeService = powerAuthSDK.timeSynchronizationService
        return timeService.isTimeSynchronized ? Date(timeIntervalSince1970: timeService.currentTime()) : Date()
    }
}
