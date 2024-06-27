//
// Copyright 2024 Wultra s.r.o.
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

/// Detailed information about displaying operation data
///
/// Contains prearranged styles for the operation attributes for the app to display
public class WMTTemplates: Codable {
    
    /// The template how the operation should look like in the list of operations
    let list: ListTemplate?
    
    /// The template for how the operation data should look like
    let detail: DetailTemplate?
    
    // MARK: - Internals
    
    private enum Keys: String, CodingKey {
        case list, detail
    }
    
    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        list = try? c.decode(ListTemplate.self, forKey: .list)
        detail = try? c.decode(DetailTemplate.self, forKey: .detail)
    }
    
    public init(list: ListTemplate?, detail: DetailTemplate?) {
        self.list = list
        self.detail = detail
    }

    /// This typealias specifies that attributes using it should refer to `WMTOperationAttributes`.
    ///
    /// AttributeName is supposed to be `WMTOperationAttribute.AttributeLabel.id`
    public typealias AttributeName = String
 
    /// ListTemplate defines how the operation should look in the list (active operations, history)
    ///
    /// List cell usually contains header, title, message(subtitle) and image
    public class ListTemplate: Codable {
        
        /// Prearranged name which can be processed by the app
        let style: String?
        
        /// Attribute which will be used for the header
        let header: AttributeName?
        
        /// Attribute which will be used for the title
        let title: AttributeName?
        
        /// Attribute which will be used for the message
        let message: AttributeName?
        
        /// Attribute which will be used for the image
        let image: AttributeName?
        
        // MARK: - Internals
        
        private enum Keys: CodingKey {
            case style, header, title, message, image
        }
        
        public required init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: Keys.self)
            self.style = try? c.decode(String.self, forKey: .style)
            self.header = try? c.decode(AttributeName.self, forKey: .header)
            self.title = try? c.decode(AttributeName.self, forKey: .title)
            self.message = try? c.decode(AttributeName.self, forKey: .message)
            self.image = try? c.decode(AttributeName.self, forKey: .image)
        }
        
        public init(style: String?, header: AttributeName?, title: AttributeName?, message: AttributeName?, image: AttributeName?) {
            self.style = style
            self.header = header
            self.title = title
            self.message = message
            self.image = image
        }
    }
    
    /// DetailTemplate defines how the operation details should appear.
    ///
    /// Each operation can be divided into sections with multiple cells.
    /// Attributes not mentioned in the `DetailTemplate` should be displayed without custom styling.
    public class DetailTemplate: Codable {
        
        /// Predefined style name that can be processed by the app to customize the overall look of the operation.
        let style: String?
        
        /// Indicates if the header should be created from form data (title, message, image) or customized for a specific operation
        let automaticHeaderSection: Bool?
        
        /// Sections of the operation data.
        let sections: [Section]?
        
        // MARK: - Internals
        
        private enum Keys: String, CodingKey {
            case style, sections
            case automaticHeaderSection = "headerSection"
        }
        
        public required init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: Keys.self)
            style = try? c.decode(String.self, forKey: .style)
            automaticHeaderSection = try? c.decode(Bool.self, forKey: .automaticHeaderSection)
            sections = try? c.decode([Section].self, forKey: .sections)
        }

        public init(style: String?, automaticHeaderSection: Bool?, sections: [Section]?) {
            self.style = style
            self.automaticHeaderSection = automaticHeaderSection
            self.sections = sections
        }
        
        /// Operation data can be divided into sections
        public class Section: Codable {
            
            /// Prearranged name which can be processed by the app to customize the section
            let style: String?
            
            /// Attribute for section title
            let title: AttributeName?
            
            /// Each section can have multiple cells of data
            let cells: [Cell]?
            
            // MARK: - Internals
            
            private enum Keys: String, CodingKey {
                case style, title, cells
            }
            
            public required init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: Keys.self)
                style = try? c.decode(String.self, forKey: .style)
                title = try? c.decode(AttributeName.self, forKey: .title)
                cells = try? c.decode([Cell].self, forKey: .cells)
            }
            
            public init(style: String?, title: AttributeName?, cells: [Cell]?) {
                self.style = style
                self.title = title
                self.cells = cells
            }
            
            /// Each section can have multiple cells of data
            public class Cell: Codable {
                
                /// Prearranged name which can be processed by the app to customize the cell
                let style: String?
                
                /// Which attribute shall be used
                let name: AttributeName?
                
                /// Should be the title visible or hidden
                let visibleTitle: Bool?
                
                /// Should be the content copyable
                let canCopy: Bool?
                
                /// Define if the cell should be collapsable
                let collapsable: Collapsable?
                
                public enum Collapsable: String, Codable {
                    /// The cell should not be collapsable
                    case no = "NO"
                    
                    /// The cell should be collapsable and in collapsed state
                    case collapsed = "COLLAPSED"
                    
                    /// The cell should be collapsable and in expanded state
                    case yes = "YES"
                }
                
                // MARK: - Internals
                
                private enum Keys: String, CodingKey {
                    case style, name, visibleTitle, canCopy, collapsable
                }
                
                public required init(from decoder: Decoder) throws {
                    let c = try decoder.container(keyedBy: Keys.self)
                    style = try? c.decode(String.self, forKey: .style)
                    name = try? c.decode(AttributeName.self, forKey: .name)
                    visibleTitle = try? c.decode(Bool.self, forKey: .visibleTitle)
                    canCopy = try? c.decode(Bool.self, forKey: .canCopy)
                    collapsable = try? c.decode(Collapsable.self, forKey: .collapsable)
                }
                
                public init(style: String?, name: AttributeName?, visibleTitle: Bool?, canCopy: Bool?, collapsable: Collapsable?) {
                    self.style = style
                    self.name = name
                    self.visibleTitle = visibleTitle
                    self.canCopy = canCopy
                    self.collapsable = collapsable
                }
            }
        }
    }
}

