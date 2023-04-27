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

/// WMTPostApprovalScreen is the base class for Post Approval screens classes
///
/// `type` define different kind of data which can be passed with operation
/// and shall be displayed before operation is confirmed
public class WMTPostApprovalScreen: Codable {
    
    /// type of PostApprovalScrren is presented with different classes (Starting with `WMTPostApprovalScreen*`)
    public let type: PostApprovalScreenType
    
    public enum PostApprovalScreenType: String, Codable {
        case review = "REVIEW"
        case redirect = "MERCHANT_REDIRECT"
        case generic = "GENERIC"
    }
    
    private enum Keys: String, CodingKey {
        case type
    }
    
    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        type = try c.decode(PostApprovalScreenType.self, forKey: .type)
    }
    
    public init(type: PostApprovalScreenType) {
        self.type = type
    }
    
    /// This is convenience function to implement Polymorphic behavior with different types of screens
    class func decode(decoder: Decoder) throws -> WMTPostApprovalScreen? {
        let c = try decoder.container(keyedBy: Keys.self)
        let t = try c.decode(String.self, forKey: .type)
        let preType = PostApprovalScreenType(rawValue: t)
        
        switch preType {
        case .review: return try WMTPostApprovalScreenReview(from: decoder)
        case .redirect: return try WMTPostApprovalScreenRedirect(from: decoder)
        case .generic: return try WMTPostApprovalScreenGeneric(from: decoder)
        default:
            D.error("Unknown postApproval type: \(t)")
            return nil
        }
    }
}

/// PostApprovalScreenPayload is base class for all payload classes
///
/// It is empty in this moment as `RedirectPostApprovalScreenPayload` is the only implemented payload
public class PostApprovalScreenPayload: Codable {
    
}

/// Payload with data about redirecting after the operation
public class RedirectPostApprovalScreenPayload: PostApprovalScreenPayload {
    
    /// Text for the button title
    public let text: String
    
    /// URL where to redirect
    public let url: String
    
    /// Countdown after which the redirect should happen in seconds
    public let countdown: Int
    
    // MARK: Internals
    
    private enum Keys: String, CodingKey {
        case text = "redirectText"
        case url = "redirectUrl"
        case countdown = "countdown"
    }
    
    public init(text: String, url: String, countdown: Int) {
        self.text = text
        self.url = url
        self.countdown = countdown
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        text = try c.decode(String.self, forKey: .text)
        url = try c.decode(String.self, forKey: .url)
        countdown = try c.decode(Int.self, forKey: .countdown)
        super.init()
    }
}
