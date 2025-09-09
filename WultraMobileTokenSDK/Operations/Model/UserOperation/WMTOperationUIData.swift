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
    
    /// Confirm and Reject buttons should be flipped both in position and style
    public let flipButtons: Bool?
    
    /// Block approval when on call (for example when on phone or skype call)
    public let blockApprovalOnCall: Bool?
    
    /// UI for multiple pre-approval screens
    public let preApprovalScreens: [WMTPreApprovalScreen]?
    
    /// UI for post-approval opration screen
    ///
    /// Type of PostApprovalScrren is presented with different classes (Starting with `WMTPostApprovalScreen*`)
    public let postApprovalScreen: WMTPostApprovalScreen?
    
    // MARK: - INTERNALS
    
    private enum Keys: String, CodingKey {
        case flipButtons, blockApprovalOnCall, postApprovalScreen
        case preApprovalScreens
        case preApprovalScreenLegacy = "preApprovalScreen" // legacy, singular
    }
    
    // TODO: REMOVE when BE is finalized
    public static var defaultPreApprovalScreensProvider: (() -> [WMTPreApprovalScreen]?)?
    
    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        flipButtons = try? c.decode(Bool.self, forKey: .flipButtons)
        blockApprovalOnCall = try? c.decode(Bool.self, forKey: .blockApprovalOnCall)
        // TODO: REMOVE when BE is finalized
        preApprovalScreens = (try? c.decode([WMTPreApprovalScreen].self, forKey: .preApprovalScreens)) ?? Self.defaultPreApprovalScreensProvider?()
        
        // 1) New plural
//        if let screens = try? c.decode([WMTPreApprovalScreen].self, forKey: .preApprovalScreens) {
//            preApprovalScreens = screens
//        
//        // 2) If legacy singular is in the payload map to plural
//        } else if c.contains(.preApprovalScreenLegacy), let legacyDecoder = try? c.superDecoder(forKey: .preApprovalScreenLegacy) {
//            preApprovalScreens = WMTPreApprovalScreen.fromLegacy(legacyDecoder)
//        } else {
//            preApprovalScreens = nil
//        }
//        
        postApprovalScreen = try? c.decode(WMTPostApprovalScreenDecodable.self, forKey: .postApprovalScreen).postApprovalObject
    }
    
    public init(flipButtons: Bool?, blockApprovalOnCall: Bool?, preApprovalScreens: [WMTPreApprovalScreen]? = nil, postApprovalScreen: WMTPostApprovalScreen?) {
        self.flipButtons = flipButtons
        self.blockApprovalOnCall = blockApprovalOnCall
        self.preApprovalScreens = preApprovalScreens
        self.postApprovalScreen = postApprovalScreen
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
