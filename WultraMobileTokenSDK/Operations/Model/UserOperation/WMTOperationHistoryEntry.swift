//
// Copyright 2022 Wultra s.r.o.
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

/// Object returned from the operation history endpoint.
public class WMTOperationHistoryEntry: Decodable {
    
    /// Processing status of the operation
    public enum Status: String, Decodable, CaseIterable {
        /// Operation was approved
        case approved = "APPROVED"
        /// Operation was rejected
        case rejected = "REJECTED"
        /// Operation is pending its resolution
        case pending = "PENDING"
        /// Operation was canceled
        case canceled = "CANCELED"
        /// Operation expired
        case expired = "EXPIRED"
        /// Operation failed
        case failed = "FAILED"
    }
    
    /// Processing status of the operation
    public let status: Status
    /// Operation
    public let operation: WMTUserOperation
    
    private enum Keys: CodingKey {
        case status
    }
    
    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        status = try c.decode(Status.self, forKey: .status)
        operation = try WMTUserOperation(from: decoder)
    }
}
