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

/// To support encoding of any `Encodable` type, we use this wrapper.
internal struct WMTAnyEncodable: Encodable {
    
    let original: Encodable

    init<T: Encodable>(_ wrapped: T) {
        original = wrapped
    }

    func encode(to encoder: Encoder) throws {
        try original.encode(to: encoder)
    }
}

// MARK: - WMTAnyEncodable Extensions

internal extension Dictionary where Key == String, Value == Encodable {
    
    /// Converts the dictionary to a dictionary with `WMTAnyEncodable` values.
    func toAnyEncodable() -> [String: WMTAnyEncodable] {
        return mapValues { WMTAnyEncodable($0) }
    }
}
