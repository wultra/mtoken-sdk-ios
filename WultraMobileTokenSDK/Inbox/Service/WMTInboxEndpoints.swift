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
import WultraPowerAuthNetworking

enum WMTInboxEndpoints {
    
    enum Count {
        typealias EndpointType = WPNEndpointAuthenticatedWithToken<WPNRequestBase, WPNResponse<WMTInboxCount>>
        static let endpoint = EndpointType(endpointURLPath: "/api/inbox/count", tokenName: "possession_universal")
    }
    
    enum MessageList {
        typealias EndpointType = WPNEndpointAuthenticatedWithToken<WPNRequest<WMTInboxGetList>, WPNResponseArray<WMTInboxMessage>>
        static let endpoint = EndpointType(endpointURLPath: "/api/inbox/message/list", tokenName: "possession_universal")
    }
    
    enum MessageDetail {
        typealias EndpointType = WPNEndpointAuthenticatedWithToken<WPNRequest<WMTInboxGetMessageDetail>, WPNResponse<WMTInboxMessageDetail>>
        static let endpoint = EndpointType(endpointURLPath: "/api/inbox/message/detail", tokenName: "possession_universal")
    }
    
    enum MessageRead {
        typealias EndpointType = WPNEndpointAuthenticatedWithToken<WPNRequest<WMTInboxSetMessageRead>, WPNResponseBase>
        static let endpoint = EndpointType(endpointURLPath: "/api/inbox/message/read", tokenName: "possession_universal")
    }
    
    enum MessageReadAll {
        typealias EndpointType = WPNEndpointAuthenticatedWithToken<WPNRequestBase, WPNResponseBase>
        static let endpoint = EndpointType(endpointURLPath: "/api/inbox/message/read-all", tokenName: "possession_universal")
    }
}
