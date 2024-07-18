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

public struct WMTUserOperationVisual {
    public let sections: [WMTUserOperationVisualSection]
}

public struct WMTUserOperationVisualSection {
    public let style: String?
    public let title: String? // not an id, actual value
    public let cells: [WMTUserOperationVisualCell]
    
    public init(style: String? = nil, title: String? = nil, cells: [WMTUserOperationVisualCell]) {
        self.style = style
        self.title = title
        self.cells = cells
    }
}

public protocol WMTUserOperationVisualCell { }

public struct WMTUserOperationHeaderVisualCell: WMTUserOperationVisualCell {
    public let value: String
}

public struct WMTUserOperationMessageVisualCell: WMTUserOperationVisualCell {
    public let value: String
}

public struct WMTUserOperationValueAttributeVisualCell: WMTUserOperationVisualCell {
    public let header: String
    public let defaultFormattedStringValue: String
    public let style: String?
    public let attribute: WMTOperationAttribute
    public let cellTemplate: WMTTemplates.DetailTemplate.Section.Cell?
}

public struct WMTUserOperationImageVisualCell: WMTUserOperationVisualCell {
    public let urlThumbnail: URL
    public let urlFull: URL?
    public let style: String?
    public let attribute: WMTOperationAttributeImage
    public let cellTemplate: WMTTemplates.DetailTemplate.Section.Cell?
    
    private let downloader = ImageDownloader.shared
}

// MARK: WMTUserOperation Detail Visual preparation extension
extension WMTUserOperation {
 
    internal func prepareVisualDetail() -> WMTUserOperationVisual {

        guard let detailTemplate = self.ui?.templates?.detail else {
            let attrs = self.formData.attributes
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
    private func createHeaderVisual(style: String? = nil) -> WMTUserOperationVisualSection {
        let defaultHeaderCell = WMTUserOperationHeaderVisualCell(value: self.formData.title)
        let defaultMessageCell = WMTUserOperationMessageVisualCell(value: self.formData.message)
        
        return WMTUserOperationVisualSection(
            style: style,
            title: nil,
            cells: [defaultHeaderCell, defaultMessageCell]
        )
    }
    
    private func createTemplateRichData(from detailTemplate: WMTTemplates.DetailTemplate) -> WMTUserOperationVisual {
        var attrs = self.formData.attributes
        
        guard let sectionsTemplate = detailTemplate.sections else {
            // Sections not specified, but style might be
            let headerSection = createHeaderVisual(style: detailTemplate.style)
            let dataSections: WMTUserOperationVisualSection = .init(cells: attrs.getRemainingCells())
            
            return WMTUserOperationVisual(sections: [headerSection, dataSections])
        }
        
        var sections = [WMTUserOperationVisualSection]()
        
        if detailTemplate.showTitleAndMessage == false {
            let dataSections = attrs.popCells(from: sectionsTemplate)
            sections.append(contentsOf: dataSections)
            sections.append(.init(cells: attrs.getRemainingCells()))
            return .init(sections: sections)
        } else {
            let headerSection = createHeaderVisual(style: detailTemplate.style)
            let dataSection = attrs.popCells(from: sectionsTemplate)
            sections.append(headerSection)
            sections.append(contentsOf: dataSection)
            sections.append(.init(cells: attrs.getRemainingCells()))
            return .init(sections: sections)
        }
    }
}

extension WMTUserOperationImageVisualCell {
    func downloadFull(callback: @escaping (UIImage?) -> Void) {
        guard let url = urlFull else {
            callback(nil)
            return
        }
        
        // Use ImageDownloader to download the image
        downloader.downloadImage(
            at: url,
            ImageDownloader.Callback { img in
                if let img {
                    callback(img)
                } else {
                    callAgain(callback: callback)
                }
            }
        )
    }

    func downloadThumbnail(callback: @escaping (UIImage?) -> Void) {
        downloader.downloadImage(
            at: urlThumbnail,
            ImageDownloader.Callback { img in
                if let img {
                    callback(img)
                } else {
                    callAgain(callback: callback)
                }
            }
        )
    }

    private func callAgain(callback: @escaping (UIImage?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            self.downloadFull(callback: callback)
        }
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
    
    mutating func popCells(from sections: [WMTTemplates.DetailTemplate.Section]) -> [WMTUserOperationVisualSection] {
        return sections.map { popCells(from: $0) }
    }
    
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
            value = ""
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
