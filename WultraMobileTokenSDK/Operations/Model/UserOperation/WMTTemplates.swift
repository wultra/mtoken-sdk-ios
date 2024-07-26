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
    
    /// How the operation should look like in the list of operations
    public let list: ListTemplate?
    
    /// How the operation detail should look like
    public let detail: DetailTemplate?
    
    // MARK: - Internals
    
    private enum Keys: String, CodingKey {
        case list, detail
    }
    
    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        
        if c.contains(.list) {
            do {
                list = try c.decode(ListTemplate.self, forKey: .list)
            } catch {
                D.error("Failed to decode \(Keys.list) - \(error), setting to null")
                list = nil
            }
        } else {
            list = nil
        }
        
        if c.contains(.detail) {
            do {
                detail = try c.decode(DetailTemplate.self, forKey: .detail)
            } catch {
                D.error("Failed to decode \(Keys.detail) - \(error), setting to null")
                detail = nil
            }
        } else {
            detail = nil
        }
    }
    
    public init(list: ListTemplate?, detail: DetailTemplate?) {
        self.list = list
        self.detail = detail
    }

    /// Value of the `AttributeId` is referencing an existing `WMTOperationAttribute` by `WMTOperationAttribute.AttributeLabel.id`
    public typealias AttributeId = String
    
    /// Value of the `AttributeFormatted` typealias contains placeholders for operation attributes,
    /// which are specified using the syntax `${operation.attribute}`.
    ///
    /// Example might be `"${operation.date} - ${operation.place}"`
    /// Placeholders in `AttributeFormatted` need to be parsed and replaced with actual attribute values.
    public typealias AttributeFormatted = String
 
    /// ListTemplate defines how the operation should look in the list (active operations, history)
    ///
    /// List cell usually contains header, title, message(subtitle) and image
    public class ListTemplate: Codable {
        
        /// Prearranged name which can be processed by the app
        public let style: String?
        
        /// Attribute which will be used for the header
        public let header: AttributeFormatted?
        
        /// Attribute which will be used for the title
        public let title: AttributeFormatted?
        
        /// Attribute which will be used for the message
        public let message: AttributeFormatted?
        
        /// Attribute which will be used for the image
        public let image: AttributeId?

        // MARK: - Internals
        
        private enum Keys: CodingKey {
            case style, header, title, message, image
        }
        
        public required init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: Keys.self)
            
            if c.contains(.style) {
                do {
                    style = try c.decode(String.self, forKey: .style)
                } catch {
                    D.error("Failed to decode \(Keys.style) - \(error), setting to null")
                    style = nil
                }
            } else {
                style = nil
            }
            
            if c.contains(.header) {
                do {
                    header = try c.decode(AttributeFormatted.self, forKey: .header)
                } catch {
                    D.error("Failed to decode \(Keys.header) - \(error), setting to null")
                    header = nil
                }
            } else {
                header = nil
            }
            
            if c.contains(.title) {
                do {
                    title = try c.decode(AttributeFormatted.self, forKey: .title)
                } catch {
                    D.error("Failed to decode \(Keys.title) - \(error), setting to null")
                    title = nil
                }
            } else {
                title = nil
            }
            
            if c.contains(.message) {
                do {
                    message = try c.decode(AttributeFormatted.self, forKey: .message)
                } catch {
                    D.error("Failed to decode \(Keys.message) - \(error), setting to null")
                    message = nil
                }
            } else {
                message = nil
            }
            
            if c.contains(.image) {
                do {
                    image = try c.decode(AttributeId.self, forKey: .image)
                } catch {
                    D.error("Failed to decode \(Keys.image) - \(error), setting to null")
                    image = nil
                }
            } else {
                image = nil
            }
        }
        
        public init(style: String?, header: AttributeFormatted?, title: AttributeFormatted?, message: AttributeFormatted?, image: AttributeId?) {
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
        public let style: String?
        
        /// Indicates if the header should be created from form data (title, message, image) or customized for a specific operation
        public let showTitleAndMessage: Bool?
        
        /// Sections of the operation data.
        public let sections: [Section]?
        
        // MARK: - Internals
        
        private enum Keys: String, CodingKey {
            case style, sections, showTitleAndMessage
        }
        
        public required init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: Keys.self)
            
            if c.contains(.style) {
                do {
                    style = try c.decode(String.self, forKey: .style)
                } catch {
                    D.error("Failed to decode \(Keys.style) - \(error), setting to null")
                    style = nil
                }
            } else {
                style = nil
            }
            
            if c.contains(.showTitleAndMessage) {
                do {
                    showTitleAndMessage = try c.decode(Bool.self, forKey: .showTitleAndMessage)
                } catch {
                    D.error("Failed to decode \(Keys.showTitleAndMessage) - \(error), setting to null")
                    showTitleAndMessage = nil
                }
            } else {
                showTitleAndMessage = nil
            }
            
            if c.contains(.sections) {
                do {
                    sections = try c.decode([Section].self, forKey: .sections)
                } catch {
                    D.error("Failed to decode \(Keys.sections) - \(error), setting to null")
                    sections = nil
                }
            } else {
                sections = nil
            }
        }

        public init(style: String?, automaticHeaderSection: Bool?, sections: [Section]?) {
            self.style = style
            self.showTitleAndMessage = automaticHeaderSection
            self.sections = sections
        }
        
        /// Operation data can be divided into sections
        public class Section: Codable {
            
            /// Prearranged name which can be processed by the app to customize the section
            public let style: String?
            
            /// Attribute for section title
            public let title: AttributeId?
            
            /// Each section can have multiple cells of data
            public let cells: [Cell]?
            
            // MARK: - Internals
            
            private enum Keys: String, CodingKey {
                case style, title, cells
            }
            
            public required init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: Keys.self)
                
                if c.contains(.style) {
                    do {
                        style = try c.decode(String.self, forKey: .style)
                    } catch {
                        D.error("Failed to decode \(Keys.style) - \(error), setting to null")
                        style = nil
                    }
                } else {
                    style = nil
                }
                
                if c.contains(.title) {
                    do {
                        title = try c.decode(AttributeId.self, forKey: .title)
                    } catch {
                        D.error("Failed to decode \(Keys.title) - \(error), setting to null")
                        title = nil
                    }
                } else {
                    title = nil
                }
                
                if c.contains(.cells) {
                    var decodedCells: [Cell] = []

                    var nestedContainer = try c.nestedUnkeyedContainer(forKey: .cells)
                    while nestedContainer.isAtEnd == false {
                        do {
                            let cell = try Cell(from: nestedContainer.superDecoder())
                            decodedCells.append(cell)
                        } catch {
                            D.error("Failed to decode \(Keys.cells) - \(error), setting to null")
                        }
                    }

                    cells = decodedCells
                } else {
                    cells = nil
                }
            }
            
            public init(style: String?, title: AttributeId?, cells: [Cell]?) {
                self.style = style
                self.title = title
                self.cells = cells
            }
            
            /// Each section can have multiple cells of data
            public class Cell: Codable {
                
                /// Which attribute shall be used
                public let name: AttributeId
                
                /// Prearranged name which can be processed by the app to customize the cell
                public let style: String?
                
                /// Should be the title visible or hidden
                public let visibleTitle: Bool?
                
                /// Should be the content copyable
                public let canCopy: Bool?
                
                /// Define if the cell should be collapsable
                public let collapsable: Collapsable?
                
                /// If value should be centered
                public let centered: Bool?
                
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
                    case style, name, visibleTitle, canCopy, collapsable, centered
                }
                
                public required init(from decoder: Decoder) throws {
                    let c = try decoder.container(keyedBy: Keys.self)
                    name = try c.decode(AttributeId.self, forKey: .name)
                    
                    if c.contains(.style) {
                        do {
                            style = try c.decode(String.self, forKey: .style)
                        } catch {
                            D.error("Failed to decode \(Keys.style) - \(error), setting to null")
                            style = nil
                        }
                    } else {
                        style = nil
                    }

                    if c.contains(.visibleTitle) {
                        do {
                            visibleTitle = try c.decode(Bool.self, forKey: .visibleTitle)
                        } catch {
                            D.error("Failed to decode \(Keys.visibleTitle) - \(error), setting to null")
                            visibleTitle = nil
                        }
                    } else {
                        visibleTitle = nil
                    }
                    
                    if c.contains(.canCopy) {
                        do {
                            canCopy = try c.decode(Bool.self, forKey: .canCopy)
                        } catch {
                            D.error("Failed to decode \(Keys.canCopy) - \(error), setting to null")
                            canCopy = nil
                        }
                    } else {
                        canCopy = nil
                    }
                    
                    if c.contains(.collapsable) {
                        do {
                            collapsable = try c.decode(Collapsable.self, forKey: .collapsable)
                        } catch {
                            D.error("Failed to decode \(Keys.collapsable) - \(error), setting to null")
                            collapsable = nil
                        }
                    } else {
                        collapsable = nil
                    }
                    
                    if c.contains(.centered) {
                        do {
                            centered = try c.decode(Bool.self, forKey: .centered)
                        } catch {
                            D.error("Failed to decode \(Keys.centered) - \(error), setting to null")
                            centered = nil
                        }
                    } else {
                        centered = nil
                    }
                }
                
                public init(style: String?, name: AttributeId, visibleTitle: Bool?, canCopy: Bool?, collapsable: Collapsable?, centered: Bool?) {
                    self.name = name
                    self.style = style
                    self.visibleTitle = visibleTitle
                    self.canCopy = canCopy
                    self.collapsable = collapsable
                    self.centered = centered
                }
            }
        }
    }
}
