/*
 * Copyright (c) 2021, Wultra s.r.o. (www.wultra.com).
 *
 * All rights reserved. This source code can be used only for purposes specified 
 * by the given license contract signed by the rightful deputy of Wultra s.r.o. 
 * This source code can be used only by the owner of the license.
 * 
 * Any disputes arising in respect of this agreement (license) shall be brought
 * before the Municipal Court of Prague.
 *
 */

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
