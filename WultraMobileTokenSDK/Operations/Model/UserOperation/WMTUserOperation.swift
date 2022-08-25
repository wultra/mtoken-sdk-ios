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
open class WMTUserOperation: WMTOperation, Codable {
    
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
}
