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

/// Helper for building additional data passed to the [IOperation].
///
/// The container allows combining generic key–value pairs with structured
/// records that define their own key and value representation.
public enum WMTMobileTokenData {}

public extension WMTMobileTokenData {

    /// Builds a map of additional data composed from generic entries
    /// and structured `WMTMobileTokenDataRecord` instances.
    final class Builder {

        /// Base content used as the initial state of the builder.
        /// This content is copied into the output first.
        private var baseMap: [String: Encodable]

        /// Generic key–value entries added directly by the application.
        private var generic: [String: Encodable] = [:]

        /// Finalized record objects to be written into the output map.
        private var records: [WMTMobileTokenDataRecord] = []

        /// Cache of *helpers/recorders* keyed by name.
        /// Helpers are not serialized; they are internal to the builder.
        private var helpers: [String: Any] = [:]

        /// Synchronization primitive that protects internal state.
        private let lock = WMTLock()

        /// Designated initializer.
        /// - Parameters:
        ///   - powerAuthSDK: `PowerAuthSDK` instance (for time sync).
        ///   - base: Optional initial content copied into the output first.
        public init(base: [String: Encodable]? = nil) {
            self.baseMap = base ?? [:]
        }

        // MARK: Generic entries

        /// Adds or replaces a generic key–value entry.
        /// If a key already exists, its value is replaced.
        @discardableResult
        public func put(_ key: String, _ value: Encodable) -> Builder {
            lock.synchronized {
                generic[key] = value
            }
            return self
        }

        // MARK: Records

        /// Adds or replaces a finalized record.
        /// If another record with the same `key` exists, it is replaced.
        @discardableResult
        public func put(_ record: WMTMobileTokenDataRecord) -> Builder {
            lock.synchronized {
                if let idx = records.firstIndex(where: { $0.key == record.key }) {
                    records.remove(at: idx)
                }
                records.append(record)
            }
            return self
        }

        /// Removes a finalized record by key. Returns `true` if removed.
        @discardableResult
        public func removeRecord(key: String) -> Bool {
            return lock.synchronized {
                if let idx = records.firstIndex(where: { $0.key == key }) {
                    records.remove(at: idx)
                    return true
                }
                return false
            }
        }

        /// Removes the given record (by its key). Returns `true` if removed.
        @discardableResult
        public func remove(_ record: WMTMobileTokenDataRecord) -> Bool {
            removeRecord(key: record.key)
        }

        /// Removes all finalized records.
        @discardableResult
        public func clearAllRecords() -> Builder {
            lock.synchronized {
                records.removeAll()
            }
            return self
        }

        // MARK: Helpers

        /// Lazily create & cache a helper/recorder instance by string key.
        /// Helpers are not part of the serialized payload.
        public func helper<T>(key: String, make: () -> T) -> T {
            return lock.synchronized {
                if let cached = helpers[key] as? T { return cached }
                let created = make()
                helpers[key] = created
                return created
            }
        }

        // MARK: Output

        /// Produces the final immutable map containing base entries,
        /// generic entries and all finalized records.
        public func build() -> [String: Encodable] {
            return lock.synchronized {
                var out = baseMap
                for (k, v) in generic { out[k] = v }
                for r in records { out[r.key] = r.toValue() }
                return out
            }
        }
    }
}

// MARK: - Built-in helper accessor

public extension WMTMobileTokenData.Builder {
    
    /// Returns the pre-approval screens recorder bound to this builder.
    ///
    /// - Behavior:
    ///   - Returns the same recorder instance for the lifetime of this builder.
    ///   - This is intentional: a single operation should produce a single
    ///     pre-approval flow payload.
    /// - Reset:
    ///   - If you need to discard the current timeline and start over,
    ///     call `pre.reset()` and continue recording.
    ///
    /// - Note:
    ///   The recorder is only attached to the output map when you call `pre.build()`.
    func preApproval(powerAuthSDK: PowerAuthSDK) -> WMTPreApprovalScreensRecorder {
        helper(key: "preApprovalScreensRecorder") {
            WMTPreApprovalScreensRecorder(powerAuthSDK: powerAuthSDK, dataBuilder: self)
        }
    }
}
