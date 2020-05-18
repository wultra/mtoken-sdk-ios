//
// Copyright 2020 Wultra s.r.o.
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

/// Attribute that describes generic key-value row to display
public class WMTOperationAttributeKeyValue: WMTOperationAttribute {
    
    /// Value of the attribute
    public let value: String
    
    
    // MARK: - INTERNALS
    
    public init(label: AttributeLabel, value: String) {
        self.value = value
        super.init(type: .keyValue, label: label)
    }
    
    private enum Keys: CodingKey {
        case value
    }
    
    public required init(from decoder: Decoder) throws {
        
        let c = try decoder.container(keyedBy: Keys.self)
        value = try c.decode(String.self, forKey: .value)
        
        try super.init(from: decoder)
    }
}
