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

/// `WMTUserOperation` is object returned from the backend that can be either approved or rejected.
/// It is usually visually presented to the user as a non-editable form with information, about
/// the real-world operation (for example login or payment).
open class WMTUserOperation: WMTOperation, Decodable {
    
    // MARK: - Data retrieved from the server
    
    /// Unique operation identifier
    public let id: String
    
    /// System name of the operation (for example login).
    ///
    /// Name of the operation shouldn't be visible to the user. You can use it to distinguish how
    /// the operation will be presented. (for example when the template for login is different than payment).
    public let name: String
    
    /// Actual data that will be signed.
    ///
    /// This shouldn't be visible to the user.
    public let data: String
    
    /// Date and time when the operation was created.
    public let operationCreated: Date
    
    /// Date and time when the operation will expire.
    ///
    /// You should never use this for hiding the operation (visually) from the user
    /// as the time set for the user system can differ with the backend.
    public let operationExpires: Date
    
    /// Data that should be presented to the user.
    public let formData: WMTOperationFormData
    
    /// Allowed signature types.
    ///
    /// This hints if the operation needs a 2nd factor or can be approved simply by
    /// tapping an approve button. If the operation requires 2FA, this value also hints if
    /// the user may use the biometry, or if a password is required.
    public let allowedSignatureType: WMTAllowedOperationSignature
    
    /// Additional UI data to present
    ///
    /// Additional UI data such as Pre-Approval Screen or Post-Approval Screen should be presented.
    public let ui: WMTOperationUIData?
    
    /// Enum-like reason why the status has changed.
    ///
    /// Max 32 characters are expected. Possible values depend on the backend implementation and configuration.
    public let statusReason: String?
    
    /// Processing status of the operation
    ///
    /// The value fallbacks to PENDING on legacy systems
    public let status: Status
    
    // MARK: - Data not retrieved from the server
    
    /// Proximity Check Data to be passed when OTP is handed to the app
    ///
    /// This data is not retrieved from the server but is set by the application.
    public var proximityCheck: WMTProximityCheck?
    
    /// Optional mobile token data, structure is customer-specific.
    /// Could be used, for example, for passing FDS data.
    /// Available with PowerAuth server 1.10+.
    /// 
    /// This data is not retrieved from the server but is set by the application.
    public var mobileTokenData: [String: Encodable]?
    
    // MARK: - Operation Status
    
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
    
    // MARK: - Internals
    
    private enum Keys: String, CodingKey {
        case id
        case name
        case data
        case operationCreated
        case operationExpires
        case formData
        case allowedSignatureType
        case ui
        case statusReason
        case status
    }
    
    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        data = try c.decode(String.self, forKey: .data)
        operationCreated = try c.decode(Date.self, forKey: .operationCreated)
        operationExpires = try c.decode(Date.self, forKey: .operationExpires)
        formData = try c.decode(WMTOperationFormData.self, forKey: .formData)
        allowedSignatureType = try c.decode(WMTAllowedOperationSignature.self, forKey: .allowedSignatureType)
        ui = try? c.decode(WMTOperationUIData.self, forKey: .ui)
        statusReason = try? c.decode(String.self, forKey: .statusReason)
        status = try c.decodeIfPresent(Status.self, forKey: .status) ?? .pending
    }
}
