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

/// Redirect screen prepares for merchant redirect
public class WMTPostApprovalScreenRedirect: WMTPostApprovalScreen {
    
    /// Heading of the post-approval screen
    public let heading: String
    
    /// Message to the user
    public let message: String
    
    /// Payload with data about action after the operation
    public let payload: WMTRedirectPostApprovalScreenPayload
    
    private enum Keys: String, CodingKey {
        case heading, message, payload
    }
    
    public init(heading: String, message: String, payload: WMTRedirectPostApprovalScreenPayload, type: ScreenType) {
        self.heading = heading
        self.message = message
        self.payload = payload
        super.init(type: type)
    }
    
    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        heading = try c.decode(String.self, forKey: .heading)
        message = try c.decode(String.self, forKey: .message)
        payload = try c.decode(WMTRedirectPostApprovalScreenPayload.self, forKey: .payload)
        try super.init(from: decoder)
    }
}

/// Payload with data about redirecting after the operation
public class WMTRedirectPostApprovalScreenPayload: WMTPostApprovalScreenPayload {
    
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
