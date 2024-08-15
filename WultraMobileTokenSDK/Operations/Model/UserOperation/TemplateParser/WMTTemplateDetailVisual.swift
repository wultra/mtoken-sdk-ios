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

/// This holds the visual data for displaying a detailed view of a user operation.
public struct WMTTemplateDetailVisual {
    
    /// Predefined style of the whole operation detail to which the app can react and adjust the operation visual
    public let style: String?
    
    /// An array of `WMTUserOperationVisualSection` defining the sections of the detailed view.
    public let sections: [WMTUserOperationVisualSection]
    
    public init(style: String?, sections: [WMTUserOperationVisualSection]) {
        self.style = style
        self.sections = sections
    }
}

/// This struct defines one section in the detailed view of a user operation.
public struct WMTUserOperationVisualSection {
    
    /// Predefined style of the section to which the app can react and adjust the operation visual
    public let style: String?
    
    /// The title value for the section
    public let title: String?
    
    /// An array of cells with `WMTOperationFormData` header and message or visual cells based on `WMTOperationAttributes`
    public let cells: [WMTUserOperationVisualCell]
    
    public init(style: String? = nil, title: String? = nil, cells: [WMTUserOperationVisualCell]) {
        self.style = style
        self.title = title
        self.cells = cells
    }
}

/// A protocol for visual cells in a user operation's detailed view.
public protocol WMTUserOperationVisualCell { }

/// `WMTUserOperationHeaderVisualCell` contains a header  in a user operation's detail header view.
///
/// This struct is used to distinguish between the default header section and custom `WMTUserOperationAttribute` sections.
public struct WMTUserOperationHeaderVisualCell: WMTUserOperationVisualCell {
    
    /// This value corresponds to `WMTOperationFormData.title`
    public let value: String
    
    public init(value: String) {
        self.value = value
    }
}

/// `WMTUserOperationMessageVisualCell` is a message cell in a user operation's header view.
///
/// This struct is used within default header section and is used to distinguished from custom `WMTUserOperationAttribute` sections.
public struct WMTUserOperationMessageVisualCell: WMTUserOperationVisualCell {
    
    /// This value corresponds to `WMTOperationFormData.message`
    public let value: String
    
    public init(value: String) {
        self.value = value
    }
}

/// `WMTUserOperationHeadingVisualCell` defines a heading cell in a user operation's detailed view.
public struct WMTUserOperationHeadingVisualCell: WMTUserOperationVisualCell {
    
    /// Single highlighted text used as a section heading
    public let header: String

    /// Predefined style of the section cell, app shall react to it and should change the visual of the cell
    public let style: String?
    
    /// The source user operation attribute.
    public let attribute: WMTOperationAttribute

    /// The template the cell was made from.
    public let cellTemplate: WMTTemplates.DetailTemplate.Section.Cell?
    
    public init(
        header: String,
        style: String? = nil,
        attribute: WMTOperationAttribute,
        cellTemplate: WMTTemplates.DetailTemplate.Section.Cell? = nil
    ) {
        self.header = header
        self.style = style
        self.attribute = attribute
        self.cellTemplate = cellTemplate
    }
}

/// `WMTUserOperationValueAttributeVisualCell` defines a key-value cell in a user operation's detailed view.
public struct WMTUserOperationValueAttributeVisualCell: WMTUserOperationVisualCell {
    /// The header text value
    public let header: String
    
    /// The text value preformatted for the cell (if the preformatted value isn't sufficient, the value from the attribute can be used)
    public let defaultFormattedStringValue: String
    
    /// Predefined style of the section cell, app shall react to it and should change the visual of the cell
    public let style: String?
    
    /// The source user operation attribute.
    public let attribute: WMTOperationAttribute
    
    /// The template the cell was made from.
    public let cellTemplate: WMTTemplates.DetailTemplate.Section.Cell?
    
    public init(
        header: String,
        defaultFormattedStringValue: String,
        style: String?,
        attribute: WMTOperationAttribute,
        cellTemplate: WMTTemplates.DetailTemplate.Section.Cell?
    ) {
        self.header = header
        self.defaultFormattedStringValue = defaultFormattedStringValue
        self.style = style
        self.attribute = attribute
        self.cellTemplate = cellTemplate
    }
}

/// `WMTUserOperationImageVisualCell` defines an image cell in a user operation's detailed view.
public struct WMTUserOperationImageVisualCell: WMTUserOperationVisualCell {
    /// The URL of the thumbnail image
    public let urlThumbnail: URL
    
    /// The URL of the full size image
    public let urlFull: URL?
    
    /// Predefined style of the section cell, app shall react to it and should change the visual of the cell
    public let style: String?
    
    /// The source user operation attribute.
    public let attribute: WMTOperationAttributeImage
    
    /// The template the cell was made from.
    public let cellTemplate: WMTTemplates.DetailTemplate.Section.Cell?
    
    public init(
        urlThumbnail: URL,
        urlFull: URL?,
        style: String?,
        attribute: WMTOperationAttributeImage,
        cellTemplate: WMTTemplates.DetailTemplate.Section.Cell?
    ) {
        self.urlThumbnail = urlThumbnail
        self.urlFull = urlFull
        self.style = style
        self.attribute = attribute
        self.cellTemplate = cellTemplate
    }
}

// MARK: WMTUserOperation Detail Visual preparation extension
extension WMTUserOperation {
 
    internal func prepareVisualDetail() -> WMTTemplateDetailVisual {

        // If templates don't contain detail return default header from `WMTOperationFormData`
        guard let detailTemplate = self.ui?.templates?.detail else {
            var sections = [createDefaultHeaderVisual()]
            if formData.attributes.isEmpty == false {
                sections.append(.init(cells: formData.attributes.getRemainingCells()))
            }
            return WMTTemplateDetailVisual(style: nil, sections: sections)
        }
        
        return createDetailVisual(from: detailTemplate)
    }
    
    // Default header visual
    private func createDefaultHeaderVisual() -> WMTUserOperationVisualSection {
        let defaultHeaderCell = WMTUserOperationHeaderVisualCell(value: self.formData.title)
        let defaultMessageCell = WMTUserOperationMessageVisualCell(value: self.formData.message)
        
        return WMTUserOperationVisualSection(
            style: nil,
            title: nil,
            cells: [defaultHeaderCell, defaultMessageCell]
        )
    }
    
    // Creates WMTTemplateDetailVisual which contains cells divided in sections
    private func createDetailVisual(from detailTemplate: WMTTemplates.DetailTemplate) -> WMTTemplateDetailVisual {
        var attrs = self.formData.attributes
        
        guard let sectionsTemplate = detailTemplate.sections else {
            // Sections not specified, but style might be
            let headerSection = createDefaultHeaderVisual()
            let dataSections: WMTUserOperationVisualSection = .init(cells: attrs.getRemainingCells())
            
            return WMTTemplateDetailVisual(style: detailTemplate.style, sections: [headerSection, dataSections])
        }
        
        var sections = [WMTUserOperationVisualSection]()
        
        // If showTitleAndMessage is explicitly false don't create default header
        // this means that the whole operation is defined by templates
        // AND `WMTOperationFormData` title and message will be ignored in visual object!!!
        if detailTemplate.showTitleAndMessage == false {
            let dataSections = attrs.popCells(from: sectionsTemplate)
            sections.append(contentsOf: dataSections)
            sections.append(.init(cells: attrs.getRemainingCells()))
            return .init(style: detailTemplate.style, sections: sections)
        } else {
            let headerSection = createDefaultHeaderVisual()
            let dataSection = attrs.popCells(from: sectionsTemplate)
            sections.append(headerSection)
            sections.append(contentsOf: dataSection)
            sections.append(.init(cells: attrs.getRemainingCells()))
            return .init(style: detailTemplate.style, sections: sections)
        }
    }
}

// MARK: - Array Extension for WMTOperationAttribute
private extension Array where Element: WMTOperationAttribute {
    
    /// Pops an attribute of the specified type by its ID.
    /// - Parameter id: The ID of the attribute.
    /// - Returns: The attribute if found, otherwise nil.
    mutating func pop<T: WMTOperationAttribute>(id: String?) -> T? {
        guard let id = id else {
            return nil
        }
        return pop(id: id)
    }
    
    mutating func pop<T: WMTOperationAttribute>(id: String) -> T? {
        guard let index = firstIndex(where: { $0.label.id == id }) else {
            return nil
        }
        guard let attr = self[index] as? T else {
            return nil
        }
        remove(at: index)
        return attr
    }
    
    /// Pops cells from the sections of the detail template.
    /// - Parameter sections: The sections of the detail template.
    /// - Returns: An array of `WMTUserOperationVisualSection` objects.
    mutating func popCells(from sections: [WMTTemplates.DetailTemplate.Section]) -> [WMTUserOperationVisualSection] {
        return sections.map { popCells(from: $0) }
    }
    
    // Note that section title is already a string value
    mutating func popCells(from section: WMTTemplates.DetailTemplate.Section) -> WMTUserOperationVisualSection {
        let sectionFilled = WMTUserOperationVisualSection(
            style: section.style,
            title: pop(id: section.title)?.label.value,
            cells: popCells(from: section)
        )
        return sectionFilled
    }
    
    mutating func popCells(from section: WMTTemplates.DetailTemplate.Section) -> [WMTUserOperationVisualCell] {
        return section.cells?.compactMap { createCellFromTemplateCell($0) } ?? []
    }
    
    mutating func createCellFromTemplateCell(_ templateCell: WMTTemplates.DetailTemplate.Section.Cell) -> WMTUserOperationVisualCell? {
        guard let attr = pop(id: templateCell.name) else {
            D.warning("Template Attribute '\(templateCell.name)', not found in FormData Attributes")
            return nil
        }
        return createCell(from: attr, templateCell: templateCell)
    }
    
    func getRemainingCells() -> [WMTUserOperationVisualCell] {
        var cells = [WMTUserOperationVisualCell]()
        for attr in self {
            if let cell = createCell(from: attr) {
                cells.append(cell)
            }
        }
        return cells
    }
    
    private func createCell(from attr: WMTOperationAttribute, templateCell: WMTTemplates.DetailTemplate.Section.Cell? = nil) -> WMTUserOperationVisualCell? {
        let value: String
        
        switch attr.type {
        case .amount:
            guard let amount = attr as? WMTOperationAttributeAmount else { return nil }
            value = amount.valueFormatted ?? "\(amount.amountFormatted) \(amount.currencyFormatted)"
        case .amountConversion:
            guard let conversion = attr as? WMTOperationAttributeAmountConversion else { return nil }
            if let sourceValue = conversion.source.valueFormatted, let targetValue = conversion.target.valueFormatted {
                value = "\(sourceValue) → \(targetValue)"
            } else {
                let source = "\(conversion.source.amountFormatted) \(conversion.source.currencyFormatted)"
                let target = "\(conversion.target.amountFormatted) \(conversion.target.currencyFormatted)"
                value = "\(source) → \(target)"
            }
        case .keyValue:
            guard let keyValue = attr as? WMTOperationAttributeKeyValue else { return nil}
            value = keyValue.value
        case .note:
            guard let note = attr as? WMTOperationAttributeNote else { return nil }
            value = note.note
        case .image:
            guard let image = attr as? WMTOperationAttributeImage else { return nil }
            return WMTUserOperationImageVisualCell(
                urlThumbnail: URL(string: image.thumbnailUrl) ?? URL(string: "error")!,
                urlFull: image.originalUrl != nil ? URL(string: image.originalUrl!) : nil,
                style: templateCell?.style,
                attribute: image,
                cellTemplate: templateCell
            )
        case .heading:
            return WMTUserOperationHeadingVisualCell(
                header: attr.label.value,
                style: templateCell?.style,
                attribute: attr,
                cellTemplate: templateCell
            )
        case .partyInfo, .unknown:
            D.warning("Using unsuported Attribute in Templates")
            value = ""
        }
        
        return WMTUserOperationValueAttributeVisualCell(
            header: attr.label.value,
            defaultFormattedStringValue: value,
            style: templateCell?.style,
            attribute: attr,
            cellTemplate: templateCell
        )
    }
}
