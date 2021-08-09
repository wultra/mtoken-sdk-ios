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

/// Third party info is for providing structured information about third party data.
///
/// This can be used for example when you're approving payment in some retail eshop,
/// in such case, information about the eshop will be filled here.
public class WMTOperationAttributePartyInfo: WMTOperationAttribute {
    
    /// Information about the 3rd party info
    public let partyInfo: WMTPartyInfo
    
    // MARK: - INTERNALS
    
    private enum Keys: CodingKey {
        case partyInfo
    }
    
    public init(label: AttributeLabel, partyInfo: WMTPartyInfo) {
        self.partyInfo = partyInfo
        super.init(type: .partyInfo, label: label)
    }
    
    public required init(from decoder: Decoder) throws {
        
        let c = try decoder.container(keyedBy: Keys.self)
        partyInfo = try c.decode(WMTPartyInfo.self, forKey: .partyInfo)
        
        try super.init(from: decoder)
    }
}

/// 3rd party retailer information
public class WMTPartyInfo: Codable {
    
    /// URL address to the logo image
    public let logoUrl: URL
    
    /// Name of the retailer
    public let name: String
    
    /// Description of the retailer
    public let description: String
    
    /// Retailer website
    public let websiteUrl: URL?
}
