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
    
    /// UI for pre-approval operation screen
    public let preApprovalScreen: WMTPreApprovalScreen?
    
    /// UI for post-approval opration screen
    ///
    /// Type of PostApprovalScrren is presented with different classes (Starting with `WMTPostApprovalScreen*`)
    public let postApprovalScreen: WMTPostApprovalScreen?
    
    /// Detailed information about displaying the operation data
    ///
    /// Contains prearranged styles for the operation attributes for the app to display
    public let templates: WMTTemplates?
    
    // MARK: - INTERNALS
    
    private enum Keys: String, CodingKey {
        case flipButtons, blockApprovalOnCall, preApprovalScreen, postApprovalScreen, templates
    }
    
    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        
        do {
            flipButtons = try c.decodeIfPresent(Bool.self, forKey: .flipButtons)
        } catch {
            D.error("Failed to decode \(Keys.flipButtons) - \(error), setting to null")
            flipButtons = nil
        }
        
        do {
            blockApprovalOnCall = try c.decodeIfPresent(Bool.self, forKey: .blockApprovalOnCall)
        } catch {
            D.error("Failed to decode \(Keys.blockApprovalOnCall) - \(error), setting to null")
            blockApprovalOnCall = nil
        }
        
        do {
            preApprovalScreen = try c.decodeIfPresent(WMTPreApprovalScreen.self, forKey: .preApprovalScreen)
        } catch {
            D.error("Failed to decode \(Keys.preApprovalScreen) - \(error), setting to null")
            preApprovalScreen = nil
        }
        
        do {
            postApprovalScreen = try c.decodeIfPresent(WMTPostApprovalScreenDecodable.self, forKey: .postApprovalScreen)?.postApprovalObject
        } catch {
            D.error("Failed to decode \(Keys.postApprovalScreen) - \(error), setting to null")
            postApprovalScreen = nil
        }
        
        do {
            templates = try c.decodeIfPresent(WMTTemplates.self, forKey: .templates)
        } catch {
            D.error("Failed to decode \(Keys.templates) - \(error), setting to null")
            templates = nil
        }
    }
    
    public init(flipButtons: Bool?, blockApprovalOnCall: Bool?, preApprovalScreen: WMTPreApprovalScreen?, postApprovalScreen: WMTPostApprovalScreen?, templates: WMTTemplates? = nil) {
        self.flipButtons = flipButtons
        self.blockApprovalOnCall = blockApprovalOnCall
        self.preApprovalScreen = preApprovalScreen
        self.postApprovalScreen = postApprovalScreen
        self.templates = templates
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
