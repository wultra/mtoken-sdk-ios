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
import WultraPowerAuthNetworking

enum WMTOperationEndpoints {
    
    enum List<T: WMTUserOperation> {
        typealias EndpointType = WPNEndpointSignedWithToken<WPNRequestBase, WMTOperationListResponse<T>>
        static var endpoint: EndpointType { WPNEndpointSignedWithToken(endpointURLPath: "/api/auth/token/app/operation/list", tokenName: "possession_universal") }
    }
    
    enum History {
        typealias EndpointType = WPNEndpointSigned<WPNRequestBase, WPNResponseArray<WMTOperationHistoryEntry>>
        static let endpoint: EndpointType = WPNEndpointSigned(endpointURLPath: "/api/auth/token/app/operation/history", uriId: "/operation/history")
    }
    
    enum Authorize {
        typealias EndpointType = WPNEndpointSigned<WPNRequest<WMTAuthorizationData>, WPNResponseBase>
        static let endpoint: EndpointType = WPNEndpointSigned(endpointURLPath: "/api/auth/token/app/operation/authorize", uriId: "/operation/authorize")
    }
    
    enum Reject {
        typealias EndpointType = WPNEndpointSigned<WPNRequest<WMTRejectionData>, WPNResponseBase>
        static let endpoint: EndpointType = WPNEndpointSigned(endpointURLPath: "/api/auth/token/app/operation/cancel", uriId: "/operation/cancel")
    }
}
