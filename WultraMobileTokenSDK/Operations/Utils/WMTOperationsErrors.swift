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

public extension WMTErrorReason {
    /// Request needs valid powerauth activation.
    static let operations_invalidActivation = WMTErrorReason(rawValue: "operations_invalidActivation")
    /// Operation is already in failed a state.
    static let operations_alreadyFailed = WMTErrorReason(rawValue: "operations_alreadyFailed")
    /// Operation is already in finished a state.
    static let operations_alreadyFinished = WMTErrorReason(rawValue: "operations_alreadyFinished")
    /// Operation is already in canceled a state.
    static let operations_alreadyCanceled = WMTErrorReason(rawValue: "operations_alreadyCanceled")
    /// Operation expired.
    static let operations_alreadyRejected = WMTErrorReason(rawValue: "operations_expired")
    /// Operation has expired when trying to approve the operation.
    static let operations_authExpired = WMTErrorReason(rawValue: "operations_authExpired")
    /// Operation has expired when trying to reject the operation.
    static let operations_rejectExpired = WMTErrorReason(rawValue: "operations_rejectExpired")
    /// Operation action failed.
    static let operations_failed = WMTErrorReason(rawValue: "operations_failed")
    
    /// Couldn't sign QR operation.
    static let operations_QROperationFailed = WMTErrorReason(rawValue: "operations_QRFailed")
}
