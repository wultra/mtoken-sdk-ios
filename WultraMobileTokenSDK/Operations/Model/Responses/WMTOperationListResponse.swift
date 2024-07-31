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
import WultraPowerAuthNetworking

// This class is public for testing purposes
public class WMTOperationListResponse<T: WMTUserOperation>: WPNResponseArray<T> {
    
    private enum Keys: CodingKey {
        case currentTimestamp
    }
    
    public let currentTimestamp: Date?
    
    public required init(from decoder: Decoder) throws {
        
        let c = try decoder.container(keyedBy: Keys.self)
        
        do {
            currentTimestamp = try c.decodeIfPresent(Date.self, forKey: .currentTimestamp)
        } catch {
            D.error("Failed to decode \(Keys.currentTimestamp) - \(error), setting to null")
            currentTimestamp = nil
        }
        try super.init(from: decoder)
    }
    
}
