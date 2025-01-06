/*
 * Copyright (c) 2024, Wultra s.r.o. (www.wultra.com).
 *
 * All rights reserved. This source code can be used only for purposes specified 
 * by the given license contract signed by the rightful deputy of Wultra s.r.o. 
 * This source code can be used only by the owner of the license.
 * 
 * Any disputes arising in respect of this agreement (license) shall be brought
 * before the Municipal Court of Prague.
 *
 */ 

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
