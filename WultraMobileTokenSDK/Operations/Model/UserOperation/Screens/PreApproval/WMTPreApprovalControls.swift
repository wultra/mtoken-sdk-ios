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
