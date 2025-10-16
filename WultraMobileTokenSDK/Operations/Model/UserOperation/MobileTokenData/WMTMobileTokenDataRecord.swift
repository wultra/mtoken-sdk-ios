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

/// Abstract base class representing a single top-level record that contributes
/// one key–value entry to the final `mobileTokenData` map.
///
/// Implementations may represent either:
///  - a **finalized record** (immutable key/value pair), or
///  - a **recorder** that collects data over time and produces its
///    value lazily through `toValue()`.
///
/// Each subclass must define its own `key` and implement `toValue()`.
/// The default `build()` implementation attaches the record to the
/// associated `WMTMobileTokenData.Builder`.
open class WMTMobileTokenDataRecord {

    // MARK: - Properties

    /// Reference to the owning data builder. Used to attach the record
    /// when `build()` is called.
    public let dataBuilder: WMTMobileTokenData.Builder

    /// Key under which this record will be serialized in the final map.
    open var key: String {
        fatalError("Subclasses must override `key`.")
    }

    // MARK: - Init

    /// Initializes a new record bound to a specific `WMTMobileTokenData.Builder`.
    public init(dataBuilder: WMTMobileTokenData.Builder) {
        self.dataBuilder = dataBuilder
    }

    // MARK: - Overridable methods

    /// Returns the value object that will be serialized into the final map.
    /// Must be implemented by subclasses.
    open func toValue() -> Encodable {
        fatalError("Subclasses must override `toValue()`.")
    }

    /// Clears internal state so the record can be reused.
    /// Default implementation does nothing.
    open func reset() { }

    // MARK: - Final methods

    /// Attaches this record to the associated builder.
    /// This is typically called after the record has been populated.
    ///
    /// Multiple calls are safe (idempotent).
    public final func build() {
        dataBuilder.put(self)
    }
}
