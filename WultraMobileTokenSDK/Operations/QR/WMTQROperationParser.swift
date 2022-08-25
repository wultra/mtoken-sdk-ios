//
// Copyright 2020 Wultra s.r.o.
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

public typealias WMTQROperationParseResult = Result<WMTQROperation, WMTQROperationParserError>

/// Parser for QR operation
public class WMTQROperationParser {
    
    public init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
    }

    /// Minimum lines in input string supported by this parser
    private static let minimumAttributeFields = 7
    
    /// Current number of lines in input string, supported by this parser
    private static let currentAttributeFields = 7
    
    /// Maximum number of operation data fields supported in this version.
    private static let maximumDataFields = 5

    /// Parses input string into `WMTQROperationData` structure.
    public func parse(string: String) -> WMTQROperationParseResult {
        // Split string by newline
        let attributes = string.split(separator: "\n", omittingEmptySubsequences: false)
        guard attributes.count >= WMTQROperationParser.minimumAttributeFields else { return .failure(.minimumAttributeFieldsRequired) }
        
        // Acquire all attributes
        let operationId     = String(attributes[0])
        let title           = parseAttributeText(from: String(attributes[1]))
        let message         = parseAttributeText(from: String(attributes[2]))
        let dataString      = String(attributes[3])
        let flagsString     = String(attributes[4])
        // Signature and nonce are always located at last lines
        let nonce           = String(attributes[attributes.count - 2])
        let signatureString = attributes[attributes.count - 1]

        // Validate operationId
        guard !operationId.isEmpty else { return .failure(.noOperationId) }
        
        // Validate signature
        guard let signature = parseSignature(signatureString) else { return .failure(.invalidSignature) }
        
        // Validate Nonce
        guard validateBase64String(nonce, min: 16, max: 16) else { return .failure(.invalidNonce) }
        
        // Parse operation data fields
        let formData: WMTQROperationData
        switch parseOperationData(string: dataString) {
        case .success(let result):
            formData = result
        case .failure(let error):
            return .failure(error)
        }

        // Rebuild signed data, without pure signature string
        guard let signedData = string.prefix(string.count - signature.signature.count).data(using: .utf8) else { return .failure(.signatureFormatError) }
        
        // Parse flags
        let flags = parseOperationFlags(string: flagsString)
        let isNewerFormat   = attributes.count > WMTQROperationParser.currentAttributeFields

        // Build final structure
        return .success(WMTQROperation(
            operationId: operationId,
            title: title,
            message: message,
            operationData: formData,
            nonce: nonce,
            flags: flags,
            signedData: signedData,
            signature: signature,
            isNewerFormat: isNewerFormat)
        )
    }
    
    /// Parses and translates input string into `QROperationFormData` structure. If nil is returned,
    /// then the input string is not recognized as form data.
    private func parseOperationData(string: String) -> Result<WMTQROperationData, WMTQROperationParserError> {
        let stringFields = splitOperationData(string: string)
        if stringFields.isEmpty {
            // No fields at all
            return .failure(.noOperationData)
        }
        
        // Get and check version
        let versionString = stringFields.first!
        guard let versionChar = versionString.first else {
            // First fields is empty string
            return .failure(.invalidVersionString)
        }
        if versionChar < "A" || versionChar > "Z" {
            // Version has to be an one capital letter
            return .failure(.invalidVersionString)
        }
        let version = WMTQROperationData.Version(rawValue: versionChar) ?? .vX
        
        // Get a template identifier
        guard let templateId = Int(versionString.suffix(versionString.count - 1)) else {
            // TemplateID is not an integer
            return .failure(.invalidTemplateId)
        }
        if templateId < 0 || templateId > 99 {
            return .failure(.invalidTemplateId)
        }
        
        // Parse operation data fields
        guard let fields = parseDataFields(fields: stringFields) else {
            return .failure(.tooManyDataFields)
        }
        
        // Everything looks good, so build a final structure now...
        return .success(WMTQROperationData(
            version: version,
            templateId: templateId,
            fields: fields,
            sourceString: string)
        )
    }
    
    /// Splits input string into array of strings, representing array of form fields.
    /// It's expected that input string contains asterisk separated list of fields.
    private func splitOperationData(string: String) -> [String] {
        // Split string by '*'
        let components = string.split(separator: "*", omittingEmptySubsequences: false)
        var fields = [String]()
        fields.reserveCapacity(components.count)
        // Handle escaped asterisk \* in array. This situation is easily detectable
        // by backslash at the end of the string.
        var appendNext = false
        for substring in components {
            if appendNext {
                // Previous string ended with backslash
                if var prev = fields.last {
                    // Remove backslash from last stored value and append this new sequence
                    prev.removeLast()
                    prev.append("*")
                    prev.append(contentsOf: substring)
                    // Replace last element with updated string
                    fields[fields.count - 1] = prev
                }
            } else {
                // Just append this string into final array
                fields.append(String(substring))
            }
            // Check if current sequence ends with backslash
            appendNext = substring.last == "\\"
        }
        return fields
    }
    
    /// Parses input string into array of Field enumerations. Returns nil if some
    /// field has
    private func parseDataFields(fields: [String]) -> [WMTQROperationData.Field]? {
        
        var result = [WMTQROperationData.Field]()
        result.reserveCapacity(fields.count - 1)
        // Skip version, which is first item in the array
        for stringField in fields[1...] {
            // Parse each field string
            guard let typeId = stringField.first else {
                // Empty string
                result.append(.empty)
                continue
            }
            switch typeId {
            case "A":
                // Amount
                if let field = parseAmount(from: stringField) {
                    result.append(field)
                    continue
                }
            case "I":
                // Iban
                if let field = parseIban(from: stringField) {
                    result.append(field)
                    continue
                }
            case "Q":
                // Any Account
                result.append(.anyAccount(account: parseFieldText(from: stringField)))
                continue
                
            case "D":
                // Date
                if let field = parseDate(from: stringField) {
                    result.append(field)
                    continue
                }
            case "R":
                // Reference
                result.append(.reference(text: parseFieldText(from: stringField)))
                continue
                
            case "N":
                // Note
                result.append(.note(text: parseFieldText(from: stringField)))
                continue
                
            case "T":
                // Text (generic)
                result.append(.text(text: parseFieldText(from: stringField)))
                continue
                
            default:
                // Fallback
                result.append(.fallback(text: parseFieldText(from: stringField), fieldType: typeId))
                continue
            }
            // Something went wrong (invalid input)
            return nil
        }
        if result.count > WMTQROperationParser.maximumDataFields {
            return nil
        }
        return result
    }
    
    /// Parses given string into QROperationFlags structure
    private func parseOperationFlags(string: String) -> QROperationFlags {
        return QROperationFlags(
            allowBiometryFactor: string.contains("B"),
            flipButtons: string.contains("X"),
            fraudWarning: string.contains("F"),
            blockWhenOnCall: string.contains("C")
        )
    }
    
    /// Returns true if provided string is in Base64 format and encoded data's length
    /// is within provided min & max limits.
    private func validateBase64String(_ string: String, min: Int, max: Int) -> Bool {
        if let data = Data(base64Encoded: string) {
            return data.count >= min && data.count <= max
        }
        return false
    }

    /// Returns operation signature object if provided string contains valid key type and signature.
    private func parseSignature(_ string: Substring) -> WMTQROperationSignature? {
        if string.isEmpty {
            return nil
        }
        let signingKey: WMTQROperationSignature.SigningKey
        switch string.prefix(1) {
        case "0":
            signingKey = .master
        case "1":
            signingKey = .personalized
        default:
            return nil
        }
        let signature = String(string.suffix(string.count - 1))
        if !validateBase64String(signature, min: 64, max: 255) {
            return nil
        }
        return WMTQROperationSignature(signingKey: signingKey, signature: signature)
    }
    
    /// Parses amount field into field enumeration.
    private func parseAmount(from string: String) -> WMTQROperationData.Field? {
        let value = string.suffix(string.count - 1)
        if value.count < 4 {
            // Isufficient length for number+currency
            return nil
        }
        let currency = value.suffix(3).uppercased()
        let amountString = value.prefix(value.count - 3)
        guard let amount = Decimal(string: String(amountString)) else {
            // Not a number...
            return nil
        }
        return .amount(amount: amount, currency: currency)
    }
    
    /// Parses IBAN[,BIC] into account field enumeration.
    private func parseIban(from string: String) -> WMTQROperationData.Field? {
        // Try to split IBAN to IBAN & BIC
        let ibanBic = string.suffix(string.count - 1)
        let components = ibanBic.split(separator: ",")
        if components.count > 2 || components.count == 0 {
            // Unsupported format
            return nil
        }
        let iban: String
        let bic: String?
        if components.count == 2 {
            iban = String(components[0])
            bic  = String(components[1])
        } else {
            iban = String(components[0])
            bic  = nil
        }
        let allowedChars = "01234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        if iban.contains(where: { !allowedChars.contains($0) }) {
            // Invalid character in IBAN
            return nil
        }
        if bic?.contains(where: { !allowedChars.contains($0) }) == true {
            // Invalid character in BIC
            return nil
        }
        return .account(iban: iban, bic: bic)
    }
    
    /// A private date formatter used for D{DATE} parsing
    private let dateFormatter: DateFormatter
    
    /// Parses YYYYMMDD date into field enumeration
    private func parseDate(from string: String) -> WMTQROperationData.Field? {
        let dateString = string.suffix(string.count - 1)
        guard dateString.count == 8 else {
            return nil
        }
        guard let date = dateFormatter.date(from: String(dateString)) else {
            return nil
        }
        return .date(date: date)
    }
    
    /// Returns parsed generic string. The input string may contain an escaped "\n" and "\\" characters.
    private func parseFieldText(from string: String) -> String {
        let text = string.suffix(string.count - 1)
        if text.contains("\\") {
            // Replace escaped "\n" and "\\"
            return text.replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\\\", with: "\\")
        }
        return String(text)
    }
    
    private func parseAttributeText(from string: String) -> String {
        if string.contains("\\") {
            // Replace escaped "\n" and "\\"
            return string.replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\\\", with: "\\")
        }
        return string
    }
}

/// Errors during QR operation parsing
public enum WMTQROperationParserError: Error {
    /// There is not enough fields in this operation. Minimum is 7
    case minimumAttributeFieldsRequired
    
    /// Operation ID is missing
    case noOperationId
    
    /// Operation has invalid signature
    case invalidSignature
    
    /// When signature cannot be converted to Data
    case signatureFormatError
    
    /// Operation has invalid nonce
    case invalidNonce
    
    /// Operation does not have any operation data
    case noOperationData
    
    /// Version character is not valid
    case invalidVersionString
    
    /// Template id must be an integer between 0 and 99
    case invalidTemplateId
    
    /// Operation has too many data fields. Maximum is 5
    case tooManyDataFields
}

public extension WMTQROperationParseResult {
    
    /// Convenience helper method for fast-checking if the result was success
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
}
