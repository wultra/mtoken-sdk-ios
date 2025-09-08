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
    
    /// Identifier of the screen
    public let id: String?
    
    /// Whether the back button should be visible
    public let backButton: Bool?
    
    /// Image identifier/url
    public let image: String?

    /// Structured elements to display on the screen
    public let elements: [WMTPreApprovalElement]?
    
    /// Approve/decline control specification
    public let controls: WMTPreApprovalControls?
    
    // MARK: - INTERNALS
    
    /// Supported types of pre-approval screen.
    public enum ScreenType: String, Codable {
        case info = "INFO"
        case warning = "WARNING"
        case qr = "QR_SCAN"
        case unknown = "UNKNOWN"
    }
    
    private enum Keys: String, CodingKey {
        case type, heading, message, id, backButton, image, elements, controls
    }
    
    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        let t = try c.decode(String.self, forKey: .type)
        type = ScreenType(rawValue: t) ?? .unknown
        heading = try c.decode(String.self, forKey: .heading)
        message = try c.decode(String.self, forKey: .message)
        id = try? c.decode(String.self, forKey: .id)
        backButton = try? c.decode(Bool.self, forKey: .backButton)
        image = try? c.decode(String.self, forKey: .image)
        elements = try? c.decode([WMTPreApprovalElement].self, forKey: .elements)
        controls = try? c.decode(WMTPreApprovalControls.self, forKey: .controls)
    }
    
    public init(
        type: ScreenType,
        heading: String,
        message: String,
        id: String? = nil,
        backButton: Bool? = nil,
        image: String? = nil,
        elements: [WMTPreApprovalElement]? = nil,
        controls: WMTPreApprovalControls? = nil) {
        self.type = type
        self.heading = heading
        self.message = message
        self.id = id
        self.backButton = backButton
        self.image = image
        self.elements = elements
        self.controls = controls
    }
}

/// Structured element rendered inside a `WMTPreApprovalScreen`.
public struct WMTPreApprovalElement: Codable {
    
    /// Unique identifier of the element
    public let id: String?
    
    /// Type of element (`LISTITEM`, `ALERT`, `BUTTON`).
    public let type: ElementType
    
    /// Style of the element (`INFO`, `WARNING`, `DANGER`).
    public let style: ElementStyle?
    
    /// Button action (only relevant for button elements).
    public let action: ButtonAction?
    
    /// Hyperlink or resource reference.
    public let href: String?
    
    /// Icon name.
    public let icon: String?
    
    /// Textual content.
    public let text: String?
    
    /// Creates a generic element for the pre-approval screen.
    /// - Parameters:
    ///   - id: Optional element identifier.
    ///   - type: Element type (`.listItem`, `.alert`, `.button`).
    ///   - style: Visual style for element.
    ///   - action: Action for buttons (ignored otherwise).
    ///   - href: Optional URL/target for button actions.
    ///   - icon: Optional asset name for an icon.
    ///   - text: Optional label text.
    public init(
        id: String? = nil,
        type: ElementType,
        style: ElementStyle? = nil,
        action: ButtonAction? = nil,
        href: String? = nil,
        icon: String? = nil,
        text: String? = nil
    ) {
        self.id = id
        self.type = type
        self.style = style
        self.action = action
        self.href = href
        self.icon = icon
        self.text = text
    }

    /// Supported element types.
    public enum ElementType: String, Codable { case listItem = "LISTITEM", alert = "ALERT", button = "BUTTON" }
    
    /// Supported element styles.
    public enum ElementStyle: String, Codable { case info = "INFO", warning = "WARNING", danger = "DANGER" }
    
    /// Supported button actions.
    public enum ButtonAction: String, Codable { case link = "LINK", mail = "MAIL", phone = "PHONE", reject = "REJECT" }
}

/// Defines approve/decline control configuration on the screen.
public struct WMTPreApprovalControls: Codable {
    
    /// Whether to flip the order of approve/decline buttons.
    public let flip: Bool?
    
    /// Axis for arranging buttons.
    public let axis: ButtonAxis?
    
    /// Specification of the decline control.
    public let decline: Decline?
    
    /// Specification of the approve control.
    public let approve: Approve?
    
    /// Creates a controls payload for the pre-approval screen.
    /// - Parameters:
    ///   - flip: When `true`, the approve control is placed before the decline control.
    ///   - axis: Layout axis for controls (`.vertical` or `.horizontal`).
    ///   - decline: Decline control spec.
    ///   - approve: Approve control spec.
    public init(
        flip: Bool? = nil,
        axis: ButtonAxis? = nil,
        decline: Decline? = nil,
        approve: Approve? = nil
    ) {
        self.flip = flip
        self.axis = axis
        self.decline = decline
        self.approve = approve
    }
    
    /// Decline control specification.
    public struct Decline: Codable {
        
        /// Type of decline action (`BACK` or `REJECT`).
        public let type: DeclineType
        
        /// Text for the decline button.
        public let text: String?
        
        /// Creates a decline control.
        /// - Parameters:
        ///   - type: `.back` or `.reject`.
        ///   - text: Optional button label override.
        public init(_ type: WMTPreApprovalControls.DeclineType, text: String? = nil) {
            self.type = type
            self.text = text
        }
    }
    
    /// Approve control specification.
    public struct Approve: Codable {
        
        /// Type of approve action (`SLIDER` or `BUTTON`).
        public let type: ApproveType
        
        /// Text for the approve control.
        public let text: String?
        
        /// Countdown timer (in seconds) before enabling the approve control.
        public let counter: Int?
        
        /// Creates an approve control.
        /// - Parameters:
        ///   - type: `.slider` or `.button`.
        ///   - text: Optional label override.
        ///   - counter: Optional countdown in seconds before enabling the control.
        public init(_ type: WMTPreApprovalControls.ApproveType, text: String? = nil, counter: Int? = nil) {
            self.type = type
            self.text = text
            self.counter = counter
        }
    }

    /// Axis for arranging controls.
    public enum ButtonAxis: String, Codable { case vertical = "VERTICAL", horizontal = "HORIZONTAL" }
    
    /// Decline action types.
    public enum DeclineType: String, Codable { case back = "BACK", reject = "REJECT" }
    
    /// Approve action types.
    public enum ApproveType: String, Codable { case slider = "SLIDER", button = "BUTTON" }
}

public extension WMTPreApprovalScreen {

    /// Build `[WMTPreApprovalScreen]` from a legacy singular payload.
    /// - Maps `"items": [...]` → `[.listItem]` elements.
    /// - Maps `"approvalType":"SLIDER"` → `controls.approve = .slider`.
    /// - Ignores any other keys (no merging with new-model fields).
    /// - Returns a one-element array on success; otherwise `nil`.
    static func fromLegacy(_ decoder: Decoder) -> [WMTPreApprovalScreen]? {

        // Peek legacy-only keys we need to translate
        struct LegacyKeys: CodingKey {
            var stringValue: String
            init?(stringValue: String) { self.stringValue = stringValue }
            var intValue: Int? { nil }
            init?(intValue: Int) { return nil }

            static let type         = LegacyKeys(stringValue: "type")!
            static let heading      = LegacyKeys(stringValue: "heading")!
            static let message      = LegacyKeys(stringValue: "message")!
            static let items        = LegacyKeys(stringValue: "items")!
            static let approvalType = LegacyKeys(stringValue: "approvalType")!
        }
        
        do {
            guard let c = try? decoder.container(keyedBy: LegacyKeys.self) else { return nil }
            
            let typeRaw   = try c.decode(String.self, forKey: .type)
            let type      = ScreenType(rawValue: typeRaw) ?? .unknown
            let heading   = try c.decode(String.self, forKey: .heading)
            let message   = try c.decode(String.self, forKey: .message)
            let items     = try c.decodeIfPresent([String].self, forKey: .items)
            let approval  = try? c.decode(String.self, forKey: .approvalType)

            // Items -> listItem elements
            let elements: [WMTPreApprovalElement]? = items?.map {
                WMTPreApprovalElement(type: .listItem, text: $0)
            }

            // controls only if approvalType == SLIDER
            let controls: WMTPreApprovalControls? = {
                guard let a = approval, a.caseInsensitiveCompare("SLIDER") == .orderedSame else { return nil }
                return WMTPreApprovalControls(approve: .init(.slider))
            }()

            // Build the new-model screen strictly from legacy bits (no mixing)
            let screen = WMTPreApprovalScreen(
                type: type,
                heading: heading,
                message: message,
                elements: elements,
                controls: controls
            )
            return [screen]
        } catch {
            D.error("Failed to parse legacy WMTPreApprovalScreen: \(error)")
            return nil
        }
    }
}
