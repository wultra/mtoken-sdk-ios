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

/// List item element (one row with optional icon + text).
public final class WMTPreApprovalElementListItem: WMTPreApprovalElement {

    /// Visual style for the list item.
    public let style: ElementStyle?
    
    /// Icon name (asset identifier).
    public let icon: String?

    private enum Keys: String, CodingKey { case style, icon }

    /// Public convenience initializer.
    public init(id: String? = nil, style: ElementStyle? = nil, icon: String? = nil, text: String? = nil) {
        self.style = style
        self.icon = icon
        super.init(id: id, type: .listItem, text: text)
    }

    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        self.style = try? c.decode(ElementStyle.self, forKey: .style)
        self.icon = try? c.decode(String.self, forKey: .icon)
        try super.init(from: decoder)
    }
}
