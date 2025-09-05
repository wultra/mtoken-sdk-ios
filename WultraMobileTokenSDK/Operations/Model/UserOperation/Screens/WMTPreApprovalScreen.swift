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

/// WMTPreApprovalScreen contains data to be presented before approving operation
///
/// `type` define different kind of data which can be passed with operation
/// and shall be displayed before operation is confirmed
public class WMTPreApprovalScreen: Codable {
    
    /// Type of PreApprovalScreen (`WARNING`, `INFO`, `QR_SCAN` or unknown for future compatibility )
    public let type: ScreenType
    
    /// Heading of the pre-approval screen
    public let heading: String
    
    /// Message to the user
    public let message: String
    
    /// Array of items to be displayed as list of choices
    public let items: [String]?
    
    /// Type of the approval button
    public let approvalType: WMTPreApprovalScreenConfirmAction?
    
    public let id: String?
    public let backButton: Bool?
    public let image: String?
    public let elements: [WMTPreApprovalElement]?
    public let controls: WMTPreApprovalControls?
    
    // MARK: - INTERNALS
    
    public enum ScreenType: String, Codable {
        case info = "INFO"
        case warning = "WARNING"
        case qr = "QR_SCAN"
        case unknown = "UNKNOWN"
    }
    
    private enum Keys: String, CodingKey {
        case type, heading, message, items, approvalType, id, backButton, image, elements, controls
    }
    
    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        let t = try c.decode(String.self, forKey: .type)
        type = ScreenType(rawValue: t) ?? .unknown
        heading = try c.decode(String.self, forKey: .heading)
        message = try c.decode(String.self, forKey: .message)
        items = try? c.decode([String].self, forKey: .items)
        approvalType = try? c.decode(WMTPreApprovalScreenConfirmAction.self, forKey: .approvalType)
        id = try? c.decode(String.self, forKey: .id)
        backButton = try? c.decode(Bool.self, forKey: .backButton)
        image = try? c.decode(String.self, forKey: .image)
        elements = try? c.decode([WMTPreApprovalElement].self, forKey: .elements)
        controls = try? c.decode(WMTPreApprovalControls.self, forKey: .controls)
    }
    
    public init(type: ScreenType, heading: String, message: String, items: [String]? = nil, approvalType: WMTPreApprovalScreenConfirmAction?, id: String? = nil, backButton: Bool? = nil, image: String? = nil, elements: [WMTPreApprovalElement]? = nil, controls: WMTPreApprovalControls? = nil) {
        self.type = type
        self.heading = heading
        self.message = message
        self.items = items
        self.approvalType = approvalType
        self.id = id
        self.backButton = backButton
        self.image = image
        self.elements = elements
        self.controls = controls
    }
}

/// Type of action which is used within Derived PreApproval classes to define
/// how the confirm action shall be performed
public enum WMTPreApprovalScreenConfirmAction: String, Codable {
    case slider = "SLIDER"
}

public struct WMTPreApprovalElement: Codable {
    public let id: String?
    public let type: ElementType
    public let style: ElementStyle?
    public let action: ButtonAction?
    public let href: String?
    public let icon: String?
    public let text: String?

    public enum ElementType: String, Codable { case listItem = "LISTITEM", alert = "ALERT", button = "BUTTON" }
    public enum ElementStyle: String, Codable { case info = "INFO", warning = "WARNING", danger = "DANGER" }
    public enum ButtonAction: String, Codable { case link = "LINK", mail = "MAIL", phone = "PHONE", reject = "REJECT" }
}

public struct WMTPreApprovalControls: Codable {
    public let flip: Bool?
    public let axis: ButtonAxis?
    public let decline: Decline?
    public let approve: Approve?

    public struct Decline: Codable {
        public let type: DeclineType
        public let text: String?
    }
    public struct Approve: Codable {
        public let type: ApproveType
        public let text: String?
        public let counter: Int?
    }

    public enum ButtonAxis: String, Codable { case vertical = "VERTICAL", horizontal = "HORIZONTAL" }
    public enum DeclineType: String, Codable { case back = "BACK", reject = "REJECT" }
    public enum ApproveType: String, Codable { case slider = "SLIDER", button = "BUTTON" }
}
