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

/// Helper used to document the user flow through Pre-approval Screens.
///
/// The recorder tracks when each screen in the Pre-approval flow is opened
/// and closed, together with the user action that caused the transition.
/// Each recorded visit contains timestamps and an optional `ScreenAction`.
///
/// When finalized via `build()`, the recorder produces a structured record
/// that can be attached to a `WMTMobileTokenData.Builder` and later serialized
/// into `mobileTokenData` during operation authorization or rejection.
public final class WMTPreApprovalScreensRecorder: WMTMobileTokenDataRecord {

    // MARK: Record metadata

    /// Top-level key under which this record is stored in `mobileTokenData`.
    public static let key = "preApprovalScreens"
    public var key: String { Self.key }

    // MARK: Action enumeration (extensible)

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

    /// Represents a single screen visit in the Pre-approval flow.
    private struct Visit: Encodable {
        let screen: String
        let timestampOpened: Date
        var timestampClosed: Date?
        var action: String?
    }

    // MARK: Internal state

    /// Parent builder to which this record attaches itself on `build()`.
    private let parent: WMTMobileTokenData.Builder

    /// Currently open visit (if any).
    private var open: Visit?

    /// Finalized visits accumulated by the recorder.
    private var finalized: [Visit] = []

    /// `true` once `build()` has been called – the record is frozen.
    private var sealed = false

    /// Frozen payload after `build()`; emitted by `toValue()`.
    private var snapshot: [Visit]?

    /// Synchronization primitive that protects recorder state.
    private let lock = WMTLock()

    // MARK: Init

    /// Creates a new recorder bound to a specific MobileTokenData builder.
    public init(parent: WMTMobileTokenData.Builder) {
        self.parent = parent
    }

    // MARK: Recording API

    /// Opens a new visit entry for the specified `id`.
    /// If another visit is already open, it is appended as-is (no close/action).
    @discardableResult
    public func begin(_ id: String) -> Self {
        lock.synchronized {
            guard sealed == false, id.isEmpty == false else { return }
            if let live = open {
                if live.screen == id { return }
                finalized.append(live)
            }
            open = Visit(screen: id, timestampOpened: now(), timestampClosed: nil, action: nil)
        }
        return self
    }

    /// Closes the current visit with the specified `action`.
    /// If `id` does not match the currently open screen, the call has no effect.
    @discardableResult
    public func end(_ id: String, action: ScreenAction) -> Self {
        lock.synchronized {
            guard sealed == false, var live = open, live.screen == id else { return }
            live.timestampClosed = now()
            live.action = action.name
            finalized.append(live)
            open = nil
        }
        return self
    }

    /// Closes any open visit and marks it with the given `action`.
    /// Useful for unexpected termination paths (dismiss, background, etc.).
    @discardableResult
    public func closeOpen(as action: ScreenAction) -> Self {
        lock.synchronized {
            guard sealed == false, var live = open else { return }
            live.timestampClosed = now()
            live.action = action.name
            finalized.append(live)
            open = nil
        }
        return self
    }

    // MARK: WMTMobileTokenDataRecord

    /// Finalizes the recorder and attaches itself to the parent builder.
    /// Multiple calls are safe (idempotent).
    public func build() {
        lock.synchronized {
            guard sealed == false else { return }
            sealed = true
            snapshot = finalized
            parent.put(self)
        }
    }

    /// Clears collected visits and allows the recorder to be used again.
    public func reset() {
        lock.synchronized {
            open = nil
            finalized.removeAll()
            snapshot = nil
            sealed = false
        }
    }

    /// Returns the frozen representation produced by `build()`.
    /// Until `build()` is called, this returns an empty array.
    public func toValue() -> Encodable {
        lock.synchronized { snapshot ?? [] as [Visit] }
    }

    // MARK: Time helper

    /// Current time using `PowerAuthSDK` time synchronization when available.
    private func now() -> Date {
        let timeService = parent.powerAuthSDK.timeSynchronizationService
        return timeService.isTimeSynchronized ? Date(timeIntervalSince1970: timeService.currentTime()) : Date()
    }
}
