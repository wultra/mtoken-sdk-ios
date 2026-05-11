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
import Testing
import WultraMobileTokenSDK

struct QROperationParserTests {

    func makeCode(
        operationId: String     = "5ff1b1ed-a3cc-45a3-8ab0-ed60950312b6",
        title: String           = "Payment",
        message: String         = "Please confirm this payment",
        operationData: String   = "A1*A100CZK*ICZ2730300000001165254011*D20180425*Thello world",
        flags: String           = "BCFX",
        otherAttrs: [String]?   = nil,
        nonce: String           = "AD8bOO0Df73kNaIGb3Vmpg==",
        signingKey: String      = "0",
        signature: String       = "MEYCIQDby1Uq+MaxiAAGzKmE/McHzNOUrvAP2qqGBvSgcdtyjgIhAMo1sgqNa1pPZTFBhhKvCKFLGDuHuTTYexdmHFjUUIJW"
        ) -> String {
        let attrs = otherAttrs == nil ? "" : String(otherAttrs!.joined(separator: "\n")) + "\n"
        return "\(operationId)\n\(title)\n\(message)\n\(operationData)\n\(flags)\n\(attrs)\(nonce)\n\(signingKey)\(signature)"
    }
    
    // MARK: - Main tests
    
    @Test
    func testCurrentFormat() { // Without TOTP
        let parser = WMTQROperationParser()
        let qrcode = makeCode()
        let expectedSignedData =
            ("5ff1b1ed-a3cc-45a3-8ab0-ed60950312b6\n" +
            "Payment\n" +
            "Please confirm this payment\n" +
            "A1*A100CZK*ICZ2730300000001165254011*D20180425*Thello world\n" +
            "BCFX\n" +
            "AD8bOO0Df73kNaIGb3Vmpg==\n" +
            "0").data(using: .utf8)
        
        guard case .success(let operation) = parser.parse(string: qrcode) else {
            Issue.record("This should be parsed")
            return
        }
        
        #expect(operation.operationId == "5ff1b1ed-a3cc-45a3-8ab0-ed60950312b6")
        #expect(operation.title == "Payment")
        #expect(operation.message == "Please confirm this payment")
        #expect(operation.flags.allowBiometryFactor == true)
        #expect(operation.flags.flipButtons == true)
        #expect(operation.flags.fraudWarning == true)
        #expect(operation.flags.blockWhenOnCall == true)
        #expect(operation.nonce == "AD8bOO0Df73kNaIGb3Vmpg==")
        #expect(operation.signature.signature == "MEYCIQDby1Uq+MaxiAAGzKmE/McHzNOUrvAP2qqGBvSgcdtyjgIhAMo1sgqNa1pPZTFBhhKvCKFLGDuHuTTYexdmHFjUUIJW")
        #expect(operation.signature.signingKey == .master)
        #expect(operation.signedData == expectedSignedData)
        
        // Operation data
        #expect(operation.operationData.version == .v1)
        #expect(operation.operationData.templateId == 1)
        #expect(operation.operationData.fields.count == 4)
        #expect(operation.operationData.sourceString == "A1*A100CZK*ICZ2730300000001165254011*D20180425*Thello world")
        
        let fields = operation.operationData.fields
        switch fields[0] {
        case .amount(let amount, let currency):
            #expect(amount == Decimal(string: "100"))
            #expect(currency == "CZK")
        default:
            Issue.record("Amount was not parsed correctly")
        }
        switch fields[1] {
        case .account(let iban, let bic):
            #expect(iban == "CZ2730300000001165254011")
            #expect(bic == nil)
        default:
            Issue.record("Account was not parsed correctly")
        }
        switch fields[2] {
        case .date(let date):
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd"
            #expect(date == formatter.date(from: "20180425"))
        default:
            Issue.record("Date was not parsed correctly")
        }
        switch fields[3] {
        case .text(let text):
            #expect(text == "hello world")
        default:
            Issue.record("Text was not parsed correctly")
        }
    }
    
    @Test
    func testCurrentFormatWithTOTP() {
        let parser = WMTQROperationParser()
        let qrcode = makeCode(otherAttrs: ["12345678"])
        let expectedSignedData =
            ("5ff1b1ed-a3cc-45a3-8ab0-ed60950312b6\n" +
            "Payment\n" +
            "Please confirm this payment\n" +
            "A1*A100CZK*ICZ2730300000001165254011*D20180425*Thello world\n" +
            "BCFX\n" +
            "12345678\n" +
            "AD8bOO0Df73kNaIGb3Vmpg==\n" +
            "0").data(using: .utf8)
        
        guard case .success(let operation) = parser.parse(string: qrcode) else {
            Issue.record("This should be parsed")
            return
        }
        
        #expect(operation.operationId == "5ff1b1ed-a3cc-45a3-8ab0-ed60950312b6")
        #expect(operation.title == "Payment")
        #expect(operation.message == "Please confirm this payment")
        #expect(operation.flags.allowBiometryFactor == true)
        #expect(operation.flags.flipButtons == true)
        #expect(operation.flags.fraudWarning == true)
        #expect(operation.flags.blockWhenOnCall == true)
        #expect(operation.totp == "12345678")
        #expect(operation.nonce == "AD8bOO0Df73kNaIGb3Vmpg==")
        #expect(operation.signature.signature == "MEYCIQDby1Uq+MaxiAAGzKmE/McHzNOUrvAP2qqGBvSgcdtyjgIhAMo1sgqNa1pPZTFBhhKvCKFLGDuHuTTYexdmHFjUUIJW")
        #expect(operation.signature.signingKey == .master)
        #expect(operation.signedData == expectedSignedData)
        
        // Operation data
        #expect(operation.operationData.version == .v1)
        #expect(operation.operationData.templateId == 1)
        #expect(operation.operationData.fields.count == 4)
        #expect(operation.operationData.sourceString == "A1*A100CZK*ICZ2730300000001165254011*D20180425*Thello world")
    }
    
    @Test
    func testForwardCompatibility() {
        let parser = WMTQROperationParser()
        let qrcode = makeCode(operationData:"B2*Xtest", otherAttrs:["12345678", "Some Additional Information"])
        let expectedSignedData =
            ("5ff1b1ed-a3cc-45a3-8ab0-ed60950312b6\n" +
            "Payment\n" +
            "Please confirm this payment\n" +
            "B2*Xtest\n" +
            "BCFX\n" +
            "12345678\n" +
            "Some Additional Information\n" +
            "AD8bOO0Df73kNaIGb3Vmpg==\n" +
            "0").data(using: .utf8)
        
        guard case .success(let operation) = parser.parse(string: qrcode) else {
            Issue.record("This should be parsed")
            return
        }
        
        #expect(operation.isNewerFormat)
        #expect(operation.signedData == expectedSignedData)
        #expect(operation.operationData.version == .vX)
        #expect(operation.operationData.fields.count == 1)
        switch operation.operationData.fields[0] {
        case .fallback(let text, let fieldType):
            #expect(text == "test")
            #expect(fieldType == "X")
        default:
            Issue.record("OperationData parser is not forward compatible")
        }
    }
    
    // MARK: - Missing or Bad attributes
    
    @Test
    func testMissingOperationId() {
        let parser = WMTQROperationParser()
        let qrcode = makeCode(operationId:"")
        let result = parser.parse(string: qrcode)
        #expect(!(result.isSuccess))
    }
    
    @Test
    func testMissingTitleOrMessage() {
        let parser = WMTQROperationParser()
        let qrcode = makeCode(title:"", message: "")
        guard case .success(let operation) = parser.parse(string: qrcode) else {
            Issue.record("This should be parsed")
            return
        }
        #expect(operation.title == "")
        #expect(operation.message == "")
    }
    
    @Test
    func testMissingOrBadOperationDataVersion() {
        let parser = WMTQROperationParser()
        ["", "A", "2", "A100", "A-100"].forEach { operationData in
            let qrcode = makeCode(operationData: operationData)
            let result = parser.parse(string: qrcode)
            #expect(!(result.isSuccess), "Operation data '\(operationData)' should not be accepted.")
        }
    }
    
    @Test
    func testMissingFlags() {
        let parser = WMTQROperationParser()
        let qrcode = makeCode(flags: "")
        guard case .success(let operation) = parser.parse(string: qrcode) else {
            Issue.record("This should be parsed")
            return
        }
        #expect(!(operation.flags.allowBiometryFactor))
        #expect(!(operation.flags.blockWhenOnCall))
        #expect(!(operation.flags.flipButtons))
        #expect(!(operation.flags.fraudWarning))
    }
    
    @Test
    func testSomeMissingFlags() {
        let parser = WMTQROperationParser()
        let qrcode = makeCode(flags: "FX")
        guard case .success(let operation) = parser.parse(string: qrcode) else {
            Issue.record("This should be parsed")
            return
        }
        #expect(!(operation.flags.allowBiometryFactor))
        #expect(!(operation.flags.blockWhenOnCall))
        #expect(operation.flags.flipButtons)
        #expect(operation.flags.fraudWarning)
    }

    @Test
    func testMissingOrBadNonce() {
        let parser = WMTQROperationParser()
        ["", "AAAA", "MEYCIQDby1Uq+MaxiAAGzKmE/McHzNOUrvAP2qqGBvSgcdtyjgIhAMo1sgqNa1pPZTFBhhKvCKFLGDuHuTTYexdmHFjUUIJW" ].forEach { nonce in
            let qrcode = makeCode(nonce: nonce)
            let result = parser.parse(string: qrcode)
            #expect(!(result.isSuccess), "Nonce '\(nonce)' should not be accepted.")
        }
    }
    
    @Test
    func testMissingOrBadSignature() {
        let parser = WMTQROperationParser()
        let qrcode = makeCode(signingKey:"", signature: "")
        #expect(!(parser.parse(string: qrcode).isSuccess))
        
        ["", "AAAA", "AD8bOO0Df73kNaIGb3Vmpg==" ].forEach { signature in
            let qrcode = makeCode(signature: signature)
            let result = parser.parse(string: qrcode)
            #expect(!(result.isSuccess), "Signature '\(signature)' should not be accepted.")
        }
        ["", "2", "X"].forEach { (signingKey) in
            let qrcode = makeCode(signingKey: signingKey)
            let result = parser.parse(string: qrcode)
            #expect(!(result.isSuccess), "Signing key '\(signingKey)' should not be accepted.")
        }
    }
    
    // MARK: - String escaping
    
    @Test
    func testAttributeStringEscaping() {
        let parser = WMTQROperationParser()
        let qrcode = makeCode(title: "Hello\\nWorld\\\\xyz", message: "Hello\\nWorld\\\\xyz\\*")
        guard case .success(let operation) = parser.parse(string: qrcode) else {
            Issue.record("This should be parsed")
            return
        }
        #expect(operation.title == "Hello\nWorld\\xyz")
        #expect(operation.message == "Hello\nWorld\\xyz\\*")
    }
    
    @Test
    func testFieldStringEscaping() {
        let parser = WMTQROperationParser()
        let qrcode = makeCode(operationData: "A1*Thello \\* asterisk*Nnew\\nline*Xback\\\\slash")
        guard case .success(let operation) = parser.parse(string: qrcode) else {
            Issue.record("This should be parsed")
            return
        }
        #expect(operation.operationData.fields.count == 3)
        let fields = operation.operationData.fields
        switch fields[0] {
        case .text(let text):
            #expect(text == "hello * asterisk")
        default:
            Issue.record()
        }
        switch fields[1] {
        case .note(let text):
            #expect(text == "new\nline")
        default:
            Issue.record()
        }
        switch fields[2] {
        case .fallback(let text, _):
            #expect(text == "back\\slash")
        default:
            Issue.record()
        }
    }
    
    // MARK: - Field types
    
    @Test
    func testFieldAmount() {
        let parser = WMTQROperationParser()
        // Valid
        let valid: [(String, Decimal, String)] = [
            ("A100CZK",         Decimal(string: "100")!,    "CZK"),
            ("A100.00EUR",      Decimal(string: "100")!,    "EUR"),
            ("A99.32USD",       Decimal(string: "99.32")!,  "USD"),
            ("A-50000.16GBP",   Decimal(string: "-50000.16")!, "GBP"),
            ("A.325CZK",        Decimal(string:"0.325")!,   "CZK"),
            // Nonsence, but allowed by simple decimal parser
            ("A.CZK",           Decimal(string:"0")!,       "CZK"),
            ("A-CZK",           Decimal(string:"0")!,       "CZK")
        ]
        valid.forEach { field, expAmount, expCurrency in
            let qrcode = makeCode(operationData: "A1*" + field)
            guard case .success(let operation) = parser.parse(string: qrcode) else {
                Issue.record("Amount \(field) should be parsed")
                return
            }
            switch operation.operationData.fields[0] {
            case .amount(let amount, let currency):
                #expect(amount == expAmount)
                #expect(currency == expCurrency)
            default:
                Issue.record()
            }
        }
        // Invalid
        [ "ACZK", "A", "A0", "AxCZK" ].forEach { field in
            let qrcode = makeCode(operationData: "A1*" + field)
            let result = parser.parse(string: qrcode)
            #expect(!(result.isSuccess), "Amount \(field) should not be accepted.")
        }
    }
    
    @Test
    func testFieldAccount() {
        let parser = WMTQROperationParser()
        // Valid
        let valid: [(String, String, String?)] = [
            ("ISOMEIBAN1234,BIC",   "SOMEIBAN1234",    "BIC"),
            ("ISOMEIBAN",           "SOMEIBAN",    nil),
            ("ISOMEIBAN,",          "SOMEIBAN",    nil),
        ]
        valid.forEach { field, expIban, expBic in
            let qrcode = makeCode(operationData: "A1*" + field)
            guard case .success(let operation) = parser.parse(string: qrcode) else {
                Issue.record("Account \(field) should be parsed")
                return
            }
            switch operation.operationData.fields[0] {
            case .account(let iban, let bic):
                #expect(iban == expIban)
                #expect(bic == expBic)
            default:
                Issue.record()
            }
        }
        // Invalid
        [ "I", "Isomeiban,", "IGOODIBAN,badbic" ].forEach { field in
            let qrcode = makeCode(operationData: "A1*" + field)
            let result = parser.parse(string: qrcode)
            #expect(!(result.isSuccess), "Account \(field) should not be accepted.")
        }
    }
    
    @Test
    func testFieldDate() {
        let parser = WMTQROperationParser()
        // Invalid dates
        [ "D", "D0", "D2004", "D20189999" ].forEach { field in
            let qrcode = makeCode(operationData: "A1*" + field)
            let result = parser.parse(string: qrcode)
            #expect(!(result.isSuccess), "Date \(field) should not be accepted.")
        }
    }
    
    @Test
    func testFieldEmpty() {
        let parser = WMTQROperationParser()
        let qrcode = makeCode(operationData: "A1*A10CZK****Ttest")
        guard case .success(let operation) = parser.parse(string: qrcode) else {
            Issue.record("This should be parsed")
            return
        }
        let fields = operation.operationData.fields
        guard fields.count == 5 else {
            Issue.record("Number of fields doesn't match")
            return
        }
        guard case .amount(_, _) = fields[0] else {
            Issue.record("First item must be Amount")
            return
        }
        guard case .empty = fields[1] else {
            Issue.record("2nd item must be Empty")
            return
        }
        guard case .empty = fields[2] else {
            Issue.record("3rd item must be Empty")
            return
        }
        guard case .empty = fields[3] else {
            Issue.record("4th item must be Empty")
            return
        }
        guard case .text(_) = fields[4] else {
            Issue.record("5th item must be Text")
            return
        }
    }
}
