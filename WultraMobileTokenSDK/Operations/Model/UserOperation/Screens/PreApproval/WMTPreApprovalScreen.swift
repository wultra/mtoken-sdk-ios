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
    
    /// Image identifier
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
        
        var decodedElements: [WMTPreApprovalElement] = []
        do {
            var container = try c.nestedUnkeyedContainer(forKey: .elements)
            // If decoding fails log it and continue decoding until the end of container
            while container.isAtEnd == false {
                do {
                    let wrapper = try WMTPreApprovalElementDecodable(from: container.superDecoder())
                    decodedElements.append(wrapper.elementObject)
                } catch {
                    D.error("Error decoding WMTPreApprovalElement: \(error)")
                }
            }
        } catch {
            D.debug("No elements in WMTPreApprovalElement: \(error)")
        }
        self.elements = decodedElements.isEmpty ? nil : decodedElements
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

public extension WMTPreApprovalScreen {

    /// Build `[WMTPreApprovalScreen]` from a legacy singular payload.
    /// - Maps `"items": [...]` → `[.listItem]` elements.
    /// - Maps `"approvalType":"SLIDER"` → `controls.approve = .slider`.
    /// - Ignores any other keys (no merging with new-model fields).
    /// - Returns a one-element array on success, otherwise `nil`.
    static func fromLegacy(_ decoder: Decoder?) -> [WMTPreApprovalScreen]? {
        guard let decoder else { return nil }
        
        // Legacy-only keys we need to translate
        enum LegacyKeys: String, CodingKey {
            case type, heading, message, items, approvalType
        }
        
        do {
            let c = try decoder.container(keyedBy: LegacyKeys.self)
            
            let typeRaw   = try c.decode(String.self, forKey: .type)
            let type      = ScreenType(rawValue: typeRaw) ?? .unknown
            let image     = "fallback_image"
            let heading   = try c.decode(String.self, forKey: .heading)
            let message   = try c.decode(String.self, forKey: .message)
            let approval  = try? c.decode(String.self, forKey: .approvalType)

            // Items -> listItem elements
            let elements: [WMTPreApprovalElement]? = {
                guard c.contains(.items) else { return nil }
                let items = (try? c.decode([String].self, forKey: .items)) ?? []
                guard !items.isEmpty else { return nil }
                return items.map { WMTPreApprovalElementListItem(text: $0) }
            }()

            // controls only if approvalType == SLIDER
            let controls = approval == "SLIDER" ? WMTPreApprovalControls(approve: .init(.slider)) : nil

            // Build the new-model screen strictly from legacy bits (no mixing)
            let screen = WMTPreApprovalScreen(
                type: type,
                heading: heading,
                message: message,
                image: image,
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

/// This class acts as a "translation layer" for decoding a polymorphic `elements` array
/// inside `WMTPreApprovalScreen` that can contain multiple element types.
class WMTPreApprovalElementDecodable: Decodable {

    let elementObject: WMTPreApprovalElement

    required init(from decoder: Decoder) throws {
        elementObject = try WMTPreApprovalElement.decode(decoder: decoder)
    }
}
