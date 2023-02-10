//
// Copyright 2023 Wultra s.r.o.
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

public class WMTOperationAttributeImage: WMTOperationAttribute {
    
    /// Image thumbnail url to the public internet
    public let thumbnailUrl: String
    
    /// Full-size image that should be displayed on thumbnail click (when not null)
    /// Url to the public internet
    public let originalUrl: String?
    
    // MARK: - INTERNALS
    
    private enum Keys: CodingKey {
        case thumbnailUrl, originalUrl
    }
    
    public init(label: AttributeLabel, thumbnailUrl: String, originalUrl: String?) {
        self.thumbnailUrl = thumbnailUrl
        self.originalUrl = originalUrl
        super.init(type: .image, label: label)
    }
    
    public required init(from decoder: Decoder) throws {
        
        let c = try decoder.container(keyedBy: Keys.self)
        
        self.thumbnailUrl = try c.decode(String.self, forKey: .thumbnailUrl)
        self.originalUrl = try? c.decode(String.self, forKey: .originalUrl)
        
        try super.init(from: decoder)
    }
}
