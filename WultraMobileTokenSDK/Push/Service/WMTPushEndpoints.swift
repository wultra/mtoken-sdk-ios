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

class WMTPushEndpoints {

    class RegisterDevice {
        
        static let url          = "/api/push/device/register/token"
        static let tokenName    = "possession_universal"
        typealias RequestData   = WMTRequest<WMTPushRegistrationData>
        typealias ResponseData  = WMTResponseBase
        
        typealias Request       = WMTHttpRequest<RequestData, ResponseData>
    }
}
