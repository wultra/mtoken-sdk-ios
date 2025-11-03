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

/// Helper for composing additional data passed with an `WMTOperation`.
public enum WMTMobileTokenData {}

public extension WMTMobileTokenData {

    /// Builds a dictionary of additional data composed from generic key-value entries
    /// and structured `WMTMobileTokenDataRecord` instances.
    ///
    /// Thread-safe: all mutations are synchronized.
    /// Replacement semantics: putting the same key again overwrites the prior value.
    final class Builder {

         /// Thread-safe key–value data dictionary.
        private var mobileTokenData: [String: Encodable]

        /// Synchronization primitive that protects internal state.
        private let lock = WMTLock()

        /// Creates a new builder.
        /// - Parameter initialData: Optional initial entries inserted into the builder.
        public init(initialData: [String: Encodable] = [:]) {
            self.mobileTokenData = initialData
        }

        /// Adds or replaces a generic key–value entry.
        ///
        /// If a key already exists, its value is replaced.
        @discardableResult
        public func put(_ key: String, _ value: Encodable) -> Builder {
            lock.synchronized {
                mobileTokenData[key] = value
            }
            return self
        }

        /// Adds or replaces a structured record under its declared `key`.
        /// The record’s `build()` is invoked and the resulting value is stored.
        ///
        /// If an entry with the same key already exists, it is replaced.
        @discardableResult
        public func put(_ record: WMTMobileTokenDataRecord) -> Builder {
            return put(record.key, record.build())
        }

        /// Removes an entry by its key.
        /// - Returns: `true` if the key was present and removed.
        @discardableResult
        public func remove(key: String) -> Bool {
            return lock.synchronized {
                mobileTokenData.removeValue(forKey: key) != nil
            }
        }

        /// Removes the given record by its `key`.
        /// - Returns: `true` if the key was present and removed.
        @discardableResult
        public func remove(_ record: WMTMobileTokenDataRecord) -> Bool {
            return remove(key: record.key)
        }
        
        /// Removes all entries from the builder.
        @discardableResult
        public func clear() -> Builder {
            lock.synchronized { mobileTokenData.removeAll() }
            return self
        }

        // MARK: Output

        /// Returns a snapshot of the collected data.
        /// The returned dictionary is a value copy and can be assigned to `operation.mobileTokenData`.
        public func build() -> [String: Encodable] {
            return lock.synchronized { mobileTokenData }
        }
    }
}
