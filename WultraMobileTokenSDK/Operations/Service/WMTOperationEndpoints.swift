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

class WMTOperationEndpoints {

    class List {
        
        static let url          = "/api/auth/token/app/operation/list"
        static let tokenName    = "possession_universal"
        typealias RequestData   = WMTRequestBase
        typealias ResponseData  = WMTResponseArray<WMTUserOperation>
        
        typealias Request       = WMTHttpRequest<RequestData, ResponseData>
    }
    
    class History {
        
        static let url          = "/api/auth/token/app/operation/history"
        static let uriId        = "/operation/history"
        typealias RequestData   = WMTRequestBase
        typealias ResponseData  = WMTResponseArray<WMTOperationHistoryEntry>
        
        typealias Request       = WMTHttpRequest<RequestData, ResponseData>
    }
    
    class Authorize {
        
        static let url          = "/api/auth/token/app/operation/authorize"
        static let uriId        = "/operation/authorize"
        typealias RequestData   = WMTRequest<WMTAuthorizationData>
        typealias ResponseData  = WMTResponseBase
        
        typealias Request       = WMTHttpRequest<RequestData, ResponseData>
    }
    
    class Reject {
        
        static let url          = "/api/auth/token/app/operation/cancel"
        static let uriId        = "/operation/cancel"
        typealias RequestData   = WMTRequest<WMTRejectionData>
        typealias ResponseData  = WMTResponseBase
        
        typealias Request       = WMTHttpRequest<RequestData, ResponseData>
    }
}
