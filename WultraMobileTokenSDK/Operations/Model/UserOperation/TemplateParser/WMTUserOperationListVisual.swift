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

public struct WMTUserOperationListVisual {
    public let header: String?
    public let title: String?
    public let message: String?
    public let style: String?
    public let thumbnailImageURL: URL?
    public let template: WMTTemplates.ListTemplate?
    
    private let downloader = ImageDownloader.shared
    
    public init(
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
    
    public func downloadThumbnail(callback: @escaping (UIImage?) -> Void) {
        
        guard let url = thumbnailImageURL else {
            callback(nil)
            return
        }
        
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
    
    public func callAgain(callback: @escaping (UIImage?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            self.downloadThumbnail(callback: callback)
        }
    }
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

// MARK: Helpers

internal extension String {
    
    // Function to replace placeholders in the template with actual values
    func replacePlaceholders(from attributes: [WMTOperationAttribute]) -> String? {
        var result = self
        
        if let placeholders = extractPlaceholders() {
            for placeholder in placeholders {
                if let value = findAttributeValue(for: placeholder, from: attributes) {
                    result = result.replacingOccurrences(of: "${\(placeholder)}", with: value)
                } else {
                    D.debug("Placeholder Attribute: \(placeholder) in WMTUserAttributes not found.")
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
