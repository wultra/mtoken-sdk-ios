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

/// Reason why the operation will be rejected
public enum WMTRejectionReason: String, Codable {
    /// User don't want to provide the reason.
    case unknown = "UNKNOWN"
    /// Operation data does not match (for example when user found a typo or other mistake)
    case incorrectData = "INCORRECT_DATA"
    /// User didn't started this operation
    case unexpectedOperation = "UNEXPECTED_OPERATION"
}
