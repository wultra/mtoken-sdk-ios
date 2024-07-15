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

import UIKit

class WMTUserOperationVisualParser {
    static func prepareDetail(operation: WMTUserOperation) -> WMTUserOperationVisual? {
        return operation.prepareVisualDetail()
    }
    
    static func prepareList(operation: WMTUserOperation) -> WMTUserOperationListVisual? {
        return operation.prepareVisualListDetail()
    }
}

// MARK: WMTUserOperation Detail Visual preparation extension
extension WMTUserOperation {
    func prepareVisualDetail() -> WMTUserOperationVisual? {
        return WMTUserOperationVisual(sections: [])
    }
}

// MARK: WMTUserOperation List Visual preparation extension
extension WMTUserOperation {

    func prepareVisualListDetail() -> WMTUserOperationListVisual? {
        guard let listTemplate = self.ui?.templates?.list else {
            return nil
        }
        let attributes = self.formData.attributes
        
        let headerAtrr = listTemplate.header?.replacePlaceholders(from: attributes)
        
        var title: String? = nil
        if let titleAttr = listTemplate.title?.replacePlaceholders(from: attributes) {
            title = titleAttr
        } else if !self.formData.message.isEmpty {
            title = self.formData.title
        }
        
        var message: String? = nil
        if let messageAttr = listTemplate.message?.replacePlaceholders(from: attributes) {
            message = messageAttr
        } else if !self.formData.message.isEmpty {
            message = self.formData.message
        }
        
        var imageUrl: URL? = nil
        if let imgAttr = listTemplate.image, let imgAttrCell = self.formData.attributes.first(where: { $0.label.id == imgAttr }) as? WMTOperationAttributeImage {
            let imageUrl = URL(string: imgAttrCell.thumbnailUrl)
        }
        
        return WMTUserOperationListVisual(
            header: headerAtrr,
            title: title,
            message: message,
            style: self.ui?.templates?.list?.style,
            thumbnailImage: imageUrl,
            template: listTemplate
        )
    }
}


struct WMTUserOperationListVisual {
    let header: String?
    let title: String?
    let message: String?
    let style: String?
    let thumbnailImage: URL?
    
    let template: WMTTemplates.ListTemplate
}

extension WMTUserOperation {
 
    func provideData() -> WMTUserOperationVisual? {

        guard let detailTemplate = self.ui?.templates?.detail else {
            var attrs = self.formData.attributes
            if attrs.isEmpty {
                return WMTUserOperationVisual(sections: [createHeaderVisual()])
            } else {
                let headerSection = createHeaderVisual()
                let dataSections: WMTUserOperationVisualSection = .init(cells: attrs.getRemainingCells())
                
                return WMTUserOperationVisual(sections: [headerSection, dataSections])
            }
        }
        
        return createTemplateRichData(from: detailTemplate)
    }
    
    // Default header
    func createHeaderVisual(style: String? = nil) -> WMTUserOperationVisualSection {
        let defaultHeaderCell = WMTUserOperationHeaderVisualCell(value: self.formData.title)
        let defaultMessageCell = WMTUserOperationMessageVisualCell(value: self.formData.message)
        
        return WMTUserOperationVisualSection(
            style: style,
            title: nil,
            cells: [defaultHeaderCell, defaultMessageCell]
        )
    }
    
    func createTemplateRichData(from detailTemplate: WMTTemplates.DetailTemplate) -> WMTUserOperationVisual {
        var attrs = self.formData.attributes
        
        guard let sectionsTemplate = detailTemplate.sections else {
            // Sections not specified, but style might be
            let headerSection = createHeaderVisual(style: detailTemplate.style)
            let dataSections: WMTUserOperationVisualSection = .init(cells: attrs.getRemainingCells())
            
            return WMTUserOperationVisual(sections: [headerSection, dataSections])
        }
        
        var sections = [WMTUserOperationVisualSection]()
        
        if detailTemplate.showTitleAndMessage == true {
            let headerSection = createHeaderVisual(style: detailTemplate.style)
            let dataSection = attrs.popSections(from: sectionsTemplate)
            sections.append(headerSection)
            sections.append(contentsOf: dataSection)
            sections.append(.init(cells: attrs.getRemainingCells()))
            return .init(sections: sections)
            
        } else {
            let dataSections = attrs.popSections(from: sectionsTemplate)
            sections.append(contentsOf: dataSections)
            sections.append(.init(cells: attrs.getRemainingCells()))
            return .init(sections: sections)
        }
    }
}

public struct WMTUserOperationVisual {
    let sections: [WMTUserOperationVisualSection]
}

public struct WMTUserOperationVisualSection {
    let style: String?
    let title: String? // not an id, actual value
    let cells: [WMTUserOperationVisualCell]
    
    init(style: String? = nil, title: String? = nil, cells: [WMTUserOperationVisualCell]) {
        self.style = style
        self.title = title
        self.cells = cells
    }
}

public protocol WMTUserOperationVisualCell { }

public struct WMTUserOperationHeaderVisualCell: WMTUserOperationVisualCell {
    let value: String
}

public struct WMTUserOperationMessageVisualCell: WMTUserOperationVisualCell {
    let value: String
}

public struct WMTUserOperationStringValueAttributeVisualCell: WMTUserOperationVisualCell {
    let header: String
    let defaultFormattedStringValue: String
    let attribute: WMTOperationAttribute
    let cellTemplate: WMTTemplates.DetailTemplate.Section.Cell?
}

public struct WMTUserOperationImageVisualCell: WMTUserOperationVisualCell {
    let urlThumbnail: URL
    let urlFull: URL?
    let attribute: WMTOperationAttributeImage
    let cellTemplate: WMTTemplates.DetailTemplate.Section.Cell?
}

extension WMTUserOperationImageVisualCell {
    func downloadFull(callback: (Result<UIImage, Error>) -> Void) {
        // ImageDownloader.shared. ....
    }
    func downloadThumbnail(callback: (Result<UIImage, Error>) -> Void) {
        // ImageDownloader.shared. ....
    }
}


// MARK: Helpers

private extension String {
    
    // Function to replace placeholders in the template with actual values
    func replacePlaceholders(from attributes: [WMTOperationAttribute]) -> String? {
        var result = self
        
        if let placeholders = extractPlaceholders() {
            for placeholder in placeholders {
                if let value = findAttributeValue(for: placeholder, from: attributes) {
                    result = result.replacingOccurrences(of: "${\(placeholder)}", with: value)
                } else {
                    D.print("Placeholder Attribute: \(placeholder) in WMTUserAttributes not found.")
                    return nil
                }
            }
        }
        return result
    }

    private func extractPlaceholders() -> [String]? {
        do {
            let regex = try NSRegularExpression(pattern: "\\$\\{(.*?)\\}", options: [])
            let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
            
            var attributeIds: [String] = []
            for match in matches {
                if let range = Range(match.range(at: 1), in: self) {
                    let key = String(self[range])
                    attributeIds.append(key)
                }
            }
            return attributeIds
        } catch {
            D.warning("Error creating NSRegularExpression: \(error) in WMTListParser.")
            return nil
        }
    }

    private func findAttributeValue(for attributeId: String, from attributes: [WMTOperationAttribute]) -> String? {
        for attribute in attributes where attribute.label.id == attributeId {
            switch attribute.type {
            case .amount:
                let attr = attribute as! WMTOperationAttributeAmount
                return attr.valueFormatted ?? "\(attr.amountFormatted) \(attr.currencyFormatted)"

            case .amountConversion:
                let attr = attribute as! WMTOperationAttributeAmountConversion
                if let sourceValue = attr.source.valueFormatted,
                   let targetValue = attr.target.valueFormatted {
                   return "\(sourceValue) → \(targetValue)"
               } else {
                   let source = "\(attr.source.amountFormatted) \(attr.source.currencyFormatted)"
                   let target = "\(attr.target.amountFormatted) \(attr.target.currencyFormatted)"
                   return "\(source) → \(target)"
               }
                          
            case .keyValue:
                return (attribute as! WMTOperationAttributeKeyValue).value
            case .note:
                return (attribute as! WMTOperationAttributeNote).note
            case .heading:
                return (attribute as! WMTOperationAttributeHeading).label.value
            case .partyInfo, .image, .unknown:
                return nil
            }
        }
        return nil
    }
}


private extension Array where Element: WMTOperationAttribute {
    
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
    
    mutating func pop(ids: [String]) -> [WMTOperationAttribute] {
        var result = [WMTOperationAttribute]()
        for id in ids {
            guard let index = firstIndex(where: { $0.label.id == id }) else {
                continue
            }
            result.append(self[index])
            remove(at: index)
        }
        return result
    }
    
    mutating func popFirst(ids: [String]) -> WMTOperationAttribute? {
        for id in ids {
            guard let index = firstIndex(where: { $0.label.id == id }) else {
                continue
            }
            remove(at: index)
            return self[index]
        }
        return nil
    }
    
    mutating func popFirstGen<T: WMTOperationAttribute>(ids: [String]) -> T? {
        for id in ids {
            guard let index = firstIndex(where: { $0.label.id == id }) else {
                continue
            }
            guard let attr = self[index] as? T else {
                continue
            }
            remove(at: index)
            return attr
        }
        return nil
    }
    
    mutating func popSections(from sections: [WMTTemplates.DetailTemplate.Section]) -> [WMTUserOperationVisualSection] {
        return sections.map { popSection(from: $0) }
    }
    
    mutating func popSection(from section: WMTTemplates.DetailTemplate.Section) -> WMTUserOperationVisualSection {
        let sectionFilled = WMTUserOperationVisualSection(
            style: section.style,
            title: pop(id: section.title)?.label.value,
            cells: popCells(from: section)
        )
        return sectionFilled
    }
    
    mutating func popCells(from section: WMTTemplates.DetailTemplate.Section) -> [WMTUserOperationVisualCell] {
        return section.cells?.compactMap { createCellAndPopAttr(from: $0) } ?? []
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
        
    mutating func createCellAndPopAttr(from templateCell: WMTTemplates.DetailTemplate.Section.Cell) -> WMTUserOperationVisualCell? {
        guard let attr = pop(id: templateCell.name) else {
            D.warning("Template Attribute '\(templateCell.name)', not found in FormData Attributes")
            return nil
        }
        return createCell(from: attr, templateCell: templateCell)
    }
    
    private func createCell(from attr: WMTOperationAttribute, templateCell: WMTTemplates.DetailTemplate.Section.Cell? = nil) -> WMTUserOperationVisualCell? {
        let value: String
        
        switch attr.type {
        case .amount:
            let amount = attr as! WMTOperationAttributeAmount
            value = amount.valueFormatted ?? "\(amount.amountFormatted) \(amount.currencyFormatted)"
        case .amountConversion:
            let conversion = attr as! WMTOperationAttributeAmountConversion
            if let sourceValue = conversion.source.valueFormatted, let targetValue = conversion.target.valueFormatted {
                value = "\(sourceValue) → \(targetValue)"
            } else {
                let source = "\(conversion.source.amountFormatted) \(conversion.source.currencyFormatted)"
                let target = "\(conversion.target.amountFormatted) \(conversion.target.currencyFormatted)"
                value = "\(source) → \(target)"
            }
        case .keyValue:
            let keyValue = attr as! WMTOperationAttributeKeyValue
            value = keyValue.value
        case .note:
            let note = attr as! WMTOperationAttributeNote
            value = note.note
        case .image:
            let image = attr as! WMTOperationAttributeImage
            return WMTUserOperationImageVisualCell(
                urlThumbnail: URL(string: image.thumbnailUrl) ?? URL(string: "error")!,
                urlFull: image.originalUrl != nil ? URL(string: image.originalUrl!) : nil,
                attribute: image,
                cellTemplate: templateCell
            )
        case .heading:
            value = ""
        case .partyInfo, .unknown:
            D.warning("Using unsuported Attribute in Templates")
            value = ""
        }
        
        return WMTUserOperationStringValueAttributeVisualCell(
            header: attr.label.value,
            defaultFormattedStringValue: value,
            attribute: attr,
            cellTemplate: templateCell
        )
    }
}
