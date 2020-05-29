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

/// Minimal concrete implementation of `WMTOperation` for convenience usage.
public class WMTLocalOperation: WMTOperation {
    
    /// Operation identifier
    public let id: String
    
    /// Data for signing
    public let data: String
    
    
    /// Creates an instance of WMTLocalOperation
    ///
    /// - Parameters:
    ///   - id: Operation identifier
    ///   - data: Data for signing
    public init(id: String, data: String) {
        self.id = id
        self.data = data
    }
}
