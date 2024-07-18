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
    
    /// Additional UI data to present
    ///
    /// Additional UI data such as Pre-Approval Screen or Post-Approval Screen should be presented.
    public let ui: WMTOperationUIData?
    // TODO: remove before merging
    ///    public let ui = prepareTemplates(response: uiTemplates)
    
    /// Proximity Check Data to be passed when OTP is handed to the app
    public var proximityCheck: WMTProximityCheck?
    
    /// Enum-like reason why the status has changed.
    ///
    /// Max 32 characters are expected. Possible values depend on the backend implementation and configuration.
    public let statusReason: String?
}

private let jsonDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
}()

private func prepareTemplates(response: String) -> WMTOperationUIData? {
    let result = try? jsonDecoder.decode(WMTOperationUIData.self, from: response.data(using: .utf8)!)
    return result
}

private let uiTemplates: String = {
"""
{
    "templates": {
        "list": {
            "header": "${operation.request_no} Withdrawal Initiation",
            "message": "${operation.tx_amount}",
            "title": "${operation.account} · ${operation.enterprise}",
            "image": "operation.image"
        },
        "detail": {
            "style": null,
            "showTitleAndMessage": false,
            "sections": [
                {
                    "style": "HEADER",
                    "cells": [
                        {
                            "style": "ROUND",
                            "name": "operation.image"
                        },
                        {
                            "style": "HEADER_TITLE",
                            "name": "operation.dapp_originUrl"
                        }
                    ]
                },
                {
                    "style": "HEADER_WARNING",
                    "title": null,
                    "cells": [
                        {
                            "style": "WARNING_NOTE",
                            "name": "operation.blind_note"
                        }
                    ]
                },
                {
                    "style": "MONEY",
                    "title": null,
                    "cells": [
                        {
                            "name": "operation.request_no"
                        },
                        {
                            "name": "operation.tx_amount",
                            "canCopy": true
                        },
                        {
                            "name": "operation.account"
                        },
                        {
                            "name": "operation.network"
                        },
                        {
                            "name": "operation.address"
                        },
                        {
                            "name": "operation.fee_amount"
                        },
                        {
                            "name": "operation.scheme"
                        }
                    ]
                },
                {
                    "style": "DESCRIPTION",
                    "cells": [
                        {
                            "name": "operation.initiated_by",
                            "visibleTitle": true
                        },
                        {
                            "style": "CONVERSION",
                            "name": "operation.location",
                            "canCopy": true,
                            "collapsable": "NO"
                        },
                        {
                            "name": "operation.initiated_at",
                            "visibleTitle": false,
                            "style": null,
                            "canCopy": false
                        },
                        {
                            "name": "operation.enterprise"
                        }
                    ]
                },
                {
                    "style": "DATA",
                    "cells": [
                        {
                            "name": "operation.tx_data",
                            "collapsable": "COLLAPSED"
                        }
                    ]
                }
            ]
        }
    }
}
"""
}()
