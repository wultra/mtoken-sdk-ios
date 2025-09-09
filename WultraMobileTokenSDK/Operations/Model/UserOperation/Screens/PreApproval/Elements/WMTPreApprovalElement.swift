//
// Copyright 2025 Wultra s.r.o.
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

/// Structured element rendered inside a `WMTPreApprovalScreen`.
///
/// `WMTPreApprovalElement` is considered to be "abstract".
/// Every concrete element type has its own strongly typed implementation.
public class WMTPreApprovalElement: Codable {

    /// Type of the element. Based on this type, a proper subclass
    /// will be chosen during deserialization.
    public enum ElementType: String, Codable {
        case listItem = "LISTITEM"   // Basic list row with optional icon + text
        case alert    = "ALERT"      // Highlighted alert box with style + text
        case button   = "BUTTON"     // Action button with action + optional href
        case unknown  = "UNKNOWN"    // Forward-compat fallback
    }
    
    /// Supported alert styles.
    public enum ElementStyle: String, Codable { case info = "INFO", warning = "WARNING", danger = "DANGER" }

    /// Unique identifier of the element.
    public let id: String?

    /// Element type (LISTITEM, ALERT, BUTTON, or UNKNOWN).
    public let type: ElementType
        
    /// Icon name (asset identifier).
    public let icon: String?
        
    /// Textual content.
    public let text: String?

    // MARK: - INTERNALS

    /// Keys common to (or used by) all element variants.
    fileprivate enum Keys: String, CodingKey {
        case id
        case type
        case icon
        case text
        // common-but-optional keys live in subclasses; we still peek them here if needed
    }

    /// Designated initializer for the base type.
    public init(id: String? = nil, type: ElementType, icon: String? = nil, text: String? = nil) {
        self.id = id
        self.type = type
        self.icon = icon
        self.text = text
    }

    /// Base decode reads common fields (`id`, `type`).
    /// Subclasses call `try super.init(from:)` at the end of their decoding.
    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        let raw = try c.decode(String.self, forKey: .type)
        self.type = ElementType(rawValue: raw) ?? .unknown
        self.id = try? c.decode(String.self, forKey: .id)
        self.icon = try? c.decode(String.self, forKey: .id)
        self.text = try? c.decode(String.self, forKey: .text)
    }

    /// Convenience function to implement polymorphic behavior in arrays with different element types.
    class func decode(decoder: Decoder) throws -> WMTPreApprovalElement {
        let c = try decoder.container(keyedBy: Keys.self)
        let rawType = try c.decode(String.self, forKey: .type)
        let t = ElementType(rawValue: rawType) ?? .unknown

        switch t {
        case .listItem: return try WMTPreApprovalElementListItem(from: decoder)
        case .alert:    return try WMTPreApprovalElementAlert(from: decoder)
        case .button:   return try WMTPreApprovalElementButton(from: decoder)
        case .unknown:  return try WMTPreApprovalElement(from: decoder)
        }
    }
}
