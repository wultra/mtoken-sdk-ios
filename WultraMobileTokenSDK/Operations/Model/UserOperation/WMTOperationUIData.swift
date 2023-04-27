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

/// Operation UI contains data for screens pre and/or post approved operation
open class WMTOperationUIData: Codable {
    
    /// Order of the buttons
    public let flipButtons: Bool?
    
    /// Block approval during incoming phone call
    public let blockApprovalOnCall: Bool?
    
    /// UI for pre-approval opration screen
    ///
    /// Note that screen can be presented with different classes (Name starts with `WMTPreApprovalScreen*` )
    public let preApprovalScreen: WMTPreApprovalScreen?
    
    /// UI for post-approval opration screen
    public let postApprovalScreen: WMTPostApprovalScreen?
    
    // MARK: - INTERNALS
    
    private enum Keys: String, CodingKey {
        case flipButtons, blockApprovalOnCall, preApprovalScreen, postApprovalScreen
    }
    
    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        flipButtons = try? c.decode(Bool.self, forKey: .flipButtons)
        blockApprovalOnCall = try? c.decode(Bool.self, forKey: .blockApprovalOnCall)
        preApprovalScreen = try? c.decode(WMTPreApprovalScreenDecodable.self, forKey: .preApprovalScreen).preApprovalObject
        postApprovalScreen = try? c.decode(WMTPostApprovalScreenDecodable.self, forKey: .postApprovalScreen).postApprovalObject
    }
    
    public init(flipButtons: Bool?, blockApprovalOnCall: Bool?, preApprovalScreen: WMTPreApprovalScreen?, postApprovalScreen: WMTPostApprovalScreen?) {
        self.flipButtons = flipButtons
        self.blockApprovalOnCall = blockApprovalOnCall
        self.preApprovalScreen = preApprovalScreen
        self.postApprovalScreen = postApprovalScreen
    }
}

// This class acts as "translation layer" for decoding polymorphic property of preApprovalScreen
// property inside OperationUIData class that can have multiple types of PreApprovalScreen inside
private class WMTPreApprovalScreenDecodable: Decodable {
    
    fileprivate let preApprovalObject: WMTPreApprovalScreen?
    
    required init(from decoder: Decoder) throws {
        preApprovalObject = try WMTPreApprovalScreen.decode(decoder: decoder)
    }
}

// This class acts as "translation layer" for decoding polymorphic property of PostApprovalScreen
// property inside OperationFormData class that can have multiple types of PreApprovalScreen inside
private class WMTPostApprovalScreenDecodable: Decodable {
    
    fileprivate let postApprovalObject: WMTPostApprovalScreen?
    
    required init(from decoder: Decoder) throws {
        postApprovalObject = try WMTPostApprovalScreen.decode(decoder: decoder)
    }
}
