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

/// A protocol that defines minimum data needed for calculating the operation signature
/// and sending it to confirmation endpoint.
public protocol WMTOperation {
    
    /// Operation identifier
    var id: String { get }
    
    /// Data for signing
    var data: String { get }
    
    /// Additional information with proximity check data
    var proximityCheck: WMTProximityCheck? { get }
}

/// WMTOperation extension which sets proximityCheck to be nil for backwards compatibility
public extension WMTOperation {
    var proximityCheck: WMTProximityCheck? { nil }
}
