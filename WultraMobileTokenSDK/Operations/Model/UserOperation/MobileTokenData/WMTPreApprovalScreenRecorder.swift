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

/// Helper recording user navigation through Pre-approval Screens.
/// Captures open/close timestamps and the action that ended each visit.
/// When `build()` (final on the base class) is called, this record is attached
/// to `WMTMobileTokenData.Builder` and later serialized to `mobileTokenData`.
public final class WMTPreApprovalScreensRecorder: WMTMobileTokenDataRecord {

    /// Top-level key under which this record is stored in `mobileTokenData`.
    public static let key = "preApprovalScreens"
    public override var key: String { Self.key }

    // MARK: Action (extensible)

    /// Extensible action set. Serializes to `name`.
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

    // MARK: Visit model

    /// One screen visit within the Pre-approval flow.
    private struct Visit: Encodable {
        let screen: String
        let timestampOpened: Date
        var timestampClosed: Date?
        var action: String?
    }

    // MARK: - State

    /// PowerAuthSDK instance from which the time synchronization service will be used
    private let powerAuthSDK: PowerAuthSDK

    /// Currently open visit (if any).
    private var openVisit: Visit?

    /// Finalized visits accumulated by the recorder.
    private var visits: [Visit] = []

    /// `true` once `build()` has been called – the record is frozen.
    private var sealed = false

    /// Synchronization primitive that protects recorder state.
    private let lock = WMTLock()

    // MARK: Init

    /// Binds this recorder to a specific MobileTokenData builder.
    public init(powerAuthSDK: PowerAuthSDK, dataBuilder: WMTMobileTokenData.Builder) {
        self.powerAuthSDK = powerAuthSDK
        super.init(dataBuilder: dataBuilder)
    }

    // MARK: Recording API

    /// Opens a new visit entry for the specified `id`.
    /// If another visit is already open, it is appended as-is (no close/action).
    @discardableResult
    public func begin(_ id: String) -> Self {
        lock.synchronized {
            guard !sealed, !id.isEmpty else { return }
            if let live = openVisit {
                if live.screen == id { return }
                visits.append(live)
            }
            openVisit = Visit(screen: id, timestampOpened: now(), timestampClosed: nil, action: nil)
        }
        return self
    }

    /// Closes the current visit with the specified `action`.
    /// If `id` does not match the currently open screen, the call has no effect.
    @discardableResult
    public func end(_ id: String, action: ScreenAction) -> Self {
        lock.synchronized {
            guard !sealed, var live = openVisit, live.screen == id else { return }
            live.timestampClosed = now()
            live.action = action.name
            visits.append(live)
            openVisit = nil
        }
        return self
    }

    // MARK: - WMTMobileTokenDataRecord overrides
    
    /// Serialize to an array of visit dictionaries; seals on first call.
    public override func toValue() -> Encodable {
        lock.synchronized {
            sealed = true
            // Only emit finalized visits.
            return visits as [Visit]
        }
    }

    /// Clear collected visits so the recorder can be reused if needed.
    public override func reset() {
        lock.synchronized {
            openVisit = nil
            visits.removeAll()
            sealed = false
        }
    }
    
    // MARK: Time helper

    /// Current time using `PowerAuthSDK` time synchronization when available.
    private func now() -> Date {
        let timeService = powerAuthSDK.timeSynchronizationService
        return timeService.isTimeSynchronized ? Date(timeIntervalSince1970: timeService.currentTime()) : Date()
    }
}
