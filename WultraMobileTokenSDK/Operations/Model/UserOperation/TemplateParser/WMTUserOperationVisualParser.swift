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

public class WMTUserOperationVisualParser {
    public static func prepareForList(operation: WMTUserOperation) -> WMTUserOperationListVisual {
        return operation.prepareVisualListDetail()
    }
    
    public static func prepareForDetail(operation: WMTUserOperation) -> WMTUserOperationVisual {
        return operation.prepareVisualDetail()
    }
}

public struct WMTUserOperationListVisual {
    public let header: String?
    public let title: String?
    public let message: String?
    public let style: String?
    public let thumbnailImageURL: URL?
    public let template: WMTTemplates.ListTemplate?
    
    private let downloader = ImageDownloader.shared
    
    init(
        header: String? = nil,
        title: String? = nil,
        message: String? = nil,
        style: String? = nil,
        thumbnailImageURL: URL? = nil,
        template: WMTTemplates.ListTemplate? = nil
    ) {
        self.header = header
        self.title = title
        self.message = message
        self.style = style
        self.thumbnailImageURL = thumbnailImageURL
        self.template = template
    }
}

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



// MARK: WMTUserOperation List Visual preparation extension
extension WMTUserOperation {

    internal func prepareVisualListDetail() -> WMTUserOperationListVisual {
        let listTemplate = self.ui?.templates?.list
        let attributes = self.formData.attributes
        let headerAtrr = listTemplate?.header?.replacePlaceholders(from: attributes)
        
        var title: String? {
            if let titleAttr = listTemplate?.title?.replacePlaceholders(from: attributes) {
                return titleAttr
            }
            
            if !self.formData.message.isEmpty {
                return self.formData.title
            }
            
            return nil
        }

        var message: String? {
            if let messageAttr = listTemplate?.message?.replacePlaceholders(from: attributes) {
                return messageAttr
            }
            
            if !self.formData.message.isEmpty {
                return self.formData.message
            }
            
            return nil
        }

        
        var imageUrl: URL? {
            if let imgAttr = listTemplate?.image,
               let imgAttrCell = self.formData.attributes
                                        .compactMap({ $0 as? WMTOperationAttributeImage })
                                        .first(where: { $0.label.id == imgAttr }) {
                return URL(string: imgAttrCell.thumbnailUrl)
            }

            if let imgAttrCell = self.formData.attributes
                                        .compactMap({ $0 as? WMTOperationAttributeImage })
                                        .first {
                return URL(string: imgAttrCell.thumbnailUrl)
            }

            return nil
        }

        return WMTUserOperationListVisual(
            header: headerAtrr,
            title: title,
            message: message,
            style: self.ui?.templates?.list?.style,
            thumbnailImageURL: imageUrl,
            template: listTemplate
        )
    }
}


extension WMTUserOperationListVisual {
    public func downloadThumbnail(callback: @escaping (UIImage?) -> Void) {
        
        guard let url = thumbnailImageURL else {
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
    
    private func callAgain(callback: @escaping (UIImage?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            self.downloadThumbnail(callback: callback)
        }
    }
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
                guard let attr = attribute as? WMTOperationAttributeAmount else { return nil }
                return attr.valueFormatted ?? "\(attr.amountFormatted) \(attr.currencyFormatted)"

            case .amountConversion:
                guard let attr = attribute as? WMTOperationAttributeAmountConversion else { return nil }
                if let sourceValue = attr.source.valueFormatted,
                   let targetValue = attr.target.valueFormatted {
                   return "\(sourceValue) → \(targetValue)"
               } else {
                   let source = "\(attr.source.amountFormatted) \(attr.source.currencyFormatted)"
                   let target = "\(attr.target.amountFormatted) \(attr.target.currencyFormatted)"
                   return "\(source) → \(target)"
               }
                          
            case .keyValue:
                guard let attr = attribute as? WMTOperationAttributeKeyValue else { return nil }
                return attr.value
            case .note:
                guard let attr = attribute as? WMTOperationAttributeNote else { return nil }
                return attr.note
            case .heading:
                guard let attr = attribute as? WMTOperationAttributeHeading else { return nil }
                return attr.label.value
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


/// Simple image URL downloader with a simple cache implementation
public class ImageDownloader {
    
    public static let shared = ImageDownloader()
    
    public class Callback {
        
        fileprivate let callback: (UIImage?) -> Void
        fileprivate(set) var canceled = false
        
        public init(callback: @escaping (UIImage?) -> Void) {
            self.callback = callback
        }
        
        public func cancel() {
            canceled = true
        }
        
        fileprivate func setResult(_ image: UIImage?) {
            guard canceled == false else {
                return
            }
            callback(image)
        }
    }
    
    private var cache: NSCache<NSString, UIImage>
    
    private var waitingList = [URL: [Callback]]()
    private let lock = WMTLock()
    
    public init(byteCacheSize: Int = 20_000_000) { // ~20 mb
        cache = NSCache()
        cache.totalCostLimit = byteCacheSize
    }
    
    /// Downloads image for given URL
    /// - Parameters:
    ///   - url: URL where the image is
    ///   - allowCache: If the image can be cached or loaded from cache
    ///   - delayError: Should error be delayed? For example, when the URL does not exist (404), it will fail in almost instant and it's better
    ///   for the UI to "simulate communication".
    ///   - completion: Completion with nil on error. Always invoked on main thread
    public func downloadImage(at url: URL, allowCache: Bool = true, delayError: Bool = true, _ callback: Callback) {
        
        if allowCache, let cached = cache.object(forKey: NSString(string: url.absoluteString)) {
            callback.setResult(cached)
            return
        }
        
        lock.synchronized {
            if var list = waitingList[url] {
                list.append(callback)
                waitingList[url] = list
            } else {
                waitingList[url] = [callback]
            }
        }
        
        DispatchQueue.global().async { [weak self] in
            
            let started = Date()
            let data = try? Data(contentsOf: url)
            let elapsed = Date().timeIntervalSince(started)
            let delay = delayError && data == nil && elapsed < 0.8
            
            DispatchQueue.main.asyncAfter(deadline: .now() + (delay ? 0.7 : 0) ) {
                
                guard let self else {
                    return
                }
                
                self.lock.synchronized {
                    if let data, let image = UIImage(data: data) {
                        if allowCache {
                            self.cache.setObject(image, forKey: NSString(string: url.absoluteString), cost: data.count)
                        }
                        self.waitingList[url]?.forEach { $0.setResult(image) }
                    } else {
                        self.waitingList[url]?.forEach { $0.setResult(nil) }
                    }
                    
                    self.waitingList.removeValue(forKey: url)
                }
            }
        }
    }
}
