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

import XCTest
import WultraMobileTokenSDK

class QROperationParserTests: XCTestCase {

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
    
    func testCurrentFormat() {
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
            XCTFail("This should be parsed")
            return
        }
        
        XCTAssertTrue(operation.operationId == "5ff1b1ed-a3cc-45a3-8ab0-ed60950312b6")
        XCTAssertTrue(operation.title == "Payment")
        XCTAssertTrue(operation.message == "Please confirm this payment")
        XCTAssertTrue(operation.flags.allowBiometryFactor == true)
        XCTAssertTrue(operation.flags.flipButtons == true)
        XCTAssertTrue(operation.flags.fraudWarning == true)
        XCTAssertTrue(operation.flags.blockWhenOnCall == true)
        XCTAssertTrue(operation.nonce == "AD8bOO0Df73kNaIGb3Vmpg==")
        XCTAssertTrue(operation.signature.signature == "MEYCIQDby1Uq+MaxiAAGzKmE/McHzNOUrvAP2qqGBvSgcdtyjgIhAMo1sgqNa1pPZTFBhhKvCKFLGDuHuTTYexdmHFjUUIJW")
        XCTAssertTrue(operation.signature.signingKey == .master)
        XCTAssertTrue(operation.signedData == expectedSignedData)
        
        // Operation data
        XCTAssertTrue(operation.operationData.version == .v1)
        XCTAssertTrue(operation.operationData.templateId == 1)
        XCTAssertTrue(operation.operationData.fields.count == 4)
        XCTAssertTrue(operation.operationData.sourceString == "A1*A100CZK*ICZ2730300000001165254011*D20180425*Thello world")
        
        let fields = operation.operationData.fields
        switch fields[0] {
        case .amount(let amount, let currency):
            XCTAssertTrue(amount == Decimal(string: "100"))
            XCTAssertTrue(currency == "CZK")
        default:
            XCTFail("Amount was not parsed correctly")
        }
        switch fields[1] {
        case .account(let iban, let bic):
            XCTAssertTrue(iban == "CZ2730300000001165254011")
            XCTAssertTrue(bic == nil)
        default:
            XCTFail("Account was not parsed correctly")
        }
        switch fields[2] {
        case .date(let date):
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd"
            XCTAssertTrue(date == formatter.date(from: "20180425"))
        default:
            XCTFail("Date was not parsed correctly")
        }
        switch fields[3] {
        case .text(let text):
            XCTAssertTrue(text == "hello world")
        default:
            XCTFail("Text was not parsed correctly")
        }
    }
    
    func testForwardCompatibility() {
        let parser = WMTQROperationParser()
        let qrcode = makeCode(operationData:"B2*Xtest", otherAttrs:["Some Additional Information"])
        let expectedSignedData =
            ("5ff1b1ed-a3cc-45a3-8ab0-ed60950312b6\n" +
            "Payment\n" +
            "Please confirm this payment\n" +
            "B2*Xtest\n" +
            "BCFX\n" +
            "Some Additional Information\n" +
            "AD8bOO0Df73kNaIGb3Vmpg==\n" +
            "0").data(using: .utf8)
        
        guard case .success(let operation) = parser.parse(string: qrcode) else {
            XCTFail("This should be parsed")
            return
        }
        
        XCTAssertTrue(operation.isNewerFormat)
        XCTAssertTrue(operation.signedData == expectedSignedData)
        XCTAssertTrue(operation.operationData.version == .vX)
        XCTAssertTrue(operation.operationData.fields.count == 1)
        switch operation.operationData.fields[0] {
        case .fallback(let text, let fieldType):
            XCTAssertTrue(text == "test")
            XCTAssertTrue(fieldType == "X")
        default:
            XCTFail("OperationData parser is not forward compatible")
        }
    }
    
    // MARK: - Missing or Bad attributes
    
    func testMissingOperationId() {
        let parser = WMTQROperationParser()
        let qrcode = makeCode(operationId:"")
        let result = parser.parse(string: qrcode)
        XCTAssertFalse(result.isSuccess)
    }
    
    func testMissingTitleOrMessage() {
        let parser = WMTQROperationParser()
        let qrcode = makeCode(title:"", message: "")
        guard case .success(let operation) = parser.parse(string: qrcode) else {
            XCTFail("This should be parsed")
            return
        }
        XCTAssertTrue(operation.title == "")
        XCTAssertTrue(operation.message == "")
    }
    
    func testMissingOrBadOperationDataVersion() {
        let parser = WMTQROperationParser()
        ["", "A", "2", "A100", "A-100"].forEach { operationData in
            let qrcode = makeCode(operationData: operationData)
            let result = parser.parse(string: qrcode)
            XCTAssertFalse(result.isSuccess, "Operation data '\(operationData)' should not be accepted.")
        }
    }
    
    func testMissingFlags() {
        let parser = WMTQROperationParser()
        let qrcode = makeCode(flags: "")
        guard case .success(let operation) = parser.parse(string: qrcode) else {
            XCTFail("This should be parsed")
            return
        }
        XCTAssertFalse(operation.flags.allowBiometryFactor)
        XCTAssertFalse(operation.flags.blockWhenOnCall)
        XCTAssertFalse(operation.flags.flipButtons)
        XCTAssertFalse(operation.flags.fraudWarning)
    }
    
    func testSomeMissingFlags() {
        let parser = WMTQROperationParser()
        let qrcode = makeCode(flags: "FX")
        guard case .success(let operation) = parser.parse(string: qrcode) else {
            XCTFail("This should be parsed")
            return
        }
        XCTAssertFalse(operation.flags.allowBiometryFactor)
        XCTAssertFalse(operation.flags.blockWhenOnCall)
        XCTAssertTrue(operation.flags.flipButtons)
        XCTAssertTrue(operation.flags.fraudWarning)
    }

    func testMissingOrBadNonce() {
        let parser = WMTQROperationParser()
        ["", "AAAA", "MEYCIQDby1Uq+MaxiAAGzKmE/McHzNOUrvAP2qqGBvSgcdtyjgIhAMo1sgqNa1pPZTFBhhKvCKFLGDuHuTTYexdmHFjUUIJW" ].forEach { nonce in
            let qrcode = makeCode(nonce: nonce)
            let result = parser.parse(string: qrcode)
            XCTAssertFalse(result.isSuccess, "Nonce '\(nonce)' should not be accepted.")
        }
    }
    
    func testMissingOrBadSignature() {
        let parser = WMTQROperationParser()
        let qrcode = makeCode(signingKey:"", signature: "")
        XCTAssertFalse(parser.parse(string: qrcode).isSuccess)
        
        ["", "AAAA", "AD8bOO0Df73kNaIGb3Vmpg==" ].forEach { signature in
            let qrcode = makeCode(signature: signature)
            let result = parser.parse(string: qrcode)
            XCTAssertFalse(result.isSuccess, "Signature '\(signature)' should not be accepted.")
        }
        ["", "2", "X"].forEach { (signingKey) in
            let qrcode = makeCode(signingKey: signingKey)
            let result = parser.parse(string: qrcode)
            XCTAssertFalse(result.isSuccess, "Signing key '\(signingKey)' should not be accepted.")
        }
    }
    
    // MARK: - String escaping
    
    func testAttributeStringEscaping() {
        let parser = WMTQROperationParser()
        let qrcode = makeCode(title: "Hello\\nWorld\\\\xyz", message: "Hello\\nWorld\\\\xyz\\*")
        guard case .success(let operation) = parser.parse(string: qrcode) else {
            XCTFail("This should be parsed")
            return
        }
        XCTAssertTrue(operation.title == "Hello\nWorld\\xyz")
        XCTAssertTrue(operation.message == "Hello\nWorld\\xyz\\*")
    }
    
    func testFieldStringEscaping() {
        let parser = WMTQROperationParser()
        let qrcode = makeCode(operationData: "A1*Thello \\* asterisk*Nnew\\nline*Xback\\\\slash")
        guard case .success(let operation) = parser.parse(string: qrcode) else {
            XCTFail("This should be parsed")
            return
        }
        XCTAssertTrue(operation.operationData.fields.count == 3)
        let fields = operation.operationData.fields
        switch fields[0] {
        case .text(let text):
            XCTAssertTrue(text == "hello * asterisk")
        default:
            XCTFail()
        }
        switch fields[1] {
        case .note(let text):
            XCTAssertTrue(text == "new\nline")
        default:
            XCTFail()
        }
        switch fields[2] {
        case .fallback(let text, _):
            XCTAssertTrue(text == "back\\slash")
        default:
            XCTFail()
        }
    }
    
    // MARK: - Field types
    
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
                XCTFail("Amount \(field) should be parsed")
                return
            }
            switch operation.operationData.fields[0] {
            case .amount(let amount, let currency):
                XCTAssertTrue(amount == expAmount)
                XCTAssertTrue(currency == expCurrency)
            default:
                XCTFail()
            }
        }
        // Invalid
        [ "ACZK", "A", "A0", "AxCZK" ].forEach { field in
            let qrcode = makeCode(operationData: "A1*" + field)
            let result = parser.parse(string: qrcode)
            XCTAssertFalse(result.isSuccess, "Amount \(field) should not be accepted.")
        }
    }
    
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
                XCTFail("Account \(field) should be parsed")
                return
            }
            switch operation.operationData.fields[0] {
            case .account(let iban, let bic):
                XCTAssertTrue(iban == expIban)
                XCTAssertTrue(bic == expBic)
            default:
                XCTFail()
            }
        }
        // Invalid
        [ "I", "Isomeiban,", "IGOODIBAN,badbic" ].forEach { field in
            let qrcode = makeCode(operationData: "A1*" + field)
            let result = parser.parse(string: qrcode)
            XCTAssertFalse(result.isSuccess, "Account \(field) should not be accepted.")
        }
    }
    
    func testFieldDate() {
        let parser = WMTQROperationParser()
        // Invalid dates
        [ "D", "D0", "D2004", "D20189999" ].forEach { field in
            let qrcode = makeCode(operationData: "A1*" + field)
            let result = parser.parse(string: qrcode)
            XCTAssertFalse(result.isSuccess, "Date \(field) should not be accepted.")
        }
    }
    
    func testFieldEmpty() {
        let parser = WMTQROperationParser()
        let qrcode = makeCode(operationData: "A1*A10CZK****Ttest")
        guard case .success(let operation) = parser.parse(string: qrcode) else {
            XCTFail("This should be parsed")
            return
        }
        let fields = operation.operationData.fields
        guard fields.count == 5 else {
            XCTFail("Number of fields doesn't match");
            return
        }
        guard case .amount(_, _) = fields[0] else {
            XCTFail("First item must be Amount")
            return
        }
        guard case .empty = fields[1] else {
            XCTFail("2nd item must be Empty")
            return
        }
        guard case .empty = fields[2] else {
            XCTFail("3rd item must be Empty")
            return
        }
        guard case .empty = fields[3] else {
            XCTFail("4th item must be Empty")
            return
        }
        guard case .text(_) = fields[4] else {
            XCTFail("5th item must be Text")
            return
        }
    }
}
