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

import Foundation
import WultraPowerAuthNetworking

/// Represents a request for fetching OIDC provider configuration.
public class WMTOIDCConfigRequest: WPNRequestBase {
    
    /// The identifier of the OIDC provider whose configuration is being requested.
    let providerId: String
    
    init(providerId: String) {
        self.providerId = providerId
        super.init()
    }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    public override func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(providerId, forKey: .providerId)
    }
    
    enum CodingKeys: String, CodingKey {
        case providerId
    }
}
