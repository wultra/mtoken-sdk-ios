//
// Copyright 2026 Wultra s.r.o.
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
import PowerAuth2
import Testing
@testable import WultraMobileTokenSDK

/// Integration tests for ``WMTQROperationParser`` initialized with a
/// `PowerAuthSDK` instance. These tests require a valid, activated
/// PowerAuth activation backed by a running server – see
/// `WultraMobileTokenSDKTests/Configs/Readme.md` for setup instructions.
final class QROperationParserIntegrationTests: BaseIntegrationTests {
    
    init() async throws {
        try await super.init()
    }
    
    // MARK: - Parser with PowerAuth
    
    /// Parsing with a valid `PowerAuthSDK` verifies the signature
    /// automatically and the full authorize + OTP flow succeeds.
    @Test
    func testParseWithPowerAuth() async throws {
        let op = try await proxy.createOperation()
        let qrData = try await proxy.getQROperation(operationId: op.operationId)
        
        let parser = WMTQROperationParser(powerAuth: pa)
        let result = parser.parse(string: qrData.operationQrCodeData)
        let qrOp = try result.get()
        
        #expect(qrOp.operationId == op.operationId)
        
        let auth = PowerAuthAuthentication.possessionWithPassword(password: pin)
        let otp = try await ops.authorize(qrOperation: qrOp, authentication: auth)
        let verified = try await proxy.verifyQROperation(operationId: op.operationId, operationData: qrData, otp: otp)
        #expect(verified.otpValid, "OTP should be valid after parsing with PowerAuth-backed parser")
    }
    
    /// When the QR payload is tampered with, the parser with `PowerAuthSDK`
    /// must return `.signatureVerificationFailed`.
    @Test
    func testParseTamperedDataFails() async throws {
        let op = try await proxy.createOperation()
        let qrData = try await proxy.getQROperation(operationId: op.operationId)
        
        // Tamper with the title line while preserving the QR structure.
        let original = qrData.operationQrCodeData
        let lines = original.split(separator: "\n", omittingEmptySubsequences: false)
        // Line at index 1 is the title – append a character to invalidate the signature.
        var tamperedLines = lines.map(String.init)
        tamperedLines[1] = tamperedLines[1] + "x"
        let tampered = tamperedLines.joined(separator: "\n")
        
        let parser = WMTQROperationParser(powerAuth: pa)
        let result = parser.parse(string: tampered)
        
        guard case .failure(let error) = result else {
            Issue.record("Tampered QR data should not parse successfully with PowerAuth verification")
            return
        }
        #expect(error == .signatureVerificationFailed)
    }
    
    /// Without `PowerAuthSDK`, the parser does not verify the signature,
    /// so tampered data still parses successfully.
    @Test
    func testParseWithoutPowerAuthDoesNotVerify() async throws {
        let op = try await proxy.createOperation()
        let qrData = try await proxy.getQROperation(operationId: op.operationId)
        
        // Tamper with the title line.
        let lines = qrData.operationQrCodeData.split(separator: "\n", omittingEmptySubsequences: false)
        var tamperedLines = lines.map(String.init)
        tamperedLines[1] = tamperedLines[1] + "x"
        let tampered = tamperedLines.joined(separator: "\n")
        
        let parser = WMTQROperationParser()
        let result = parser.parse(string: tampered)
        
        // Without PowerAuth the tampered data should still parse.
        #expect(result.isSuccess, "Parser without PowerAuth should not verify signature")
        
        // Verification should fail because of tampering
        #expect(throws: NSError.self, performing: { try self.pa.verifyDigitalSignature(of: try result.get()) })
    }
    
    /// `PowerAuthSDK.verifyDigitalSignature(of:)` extension succeeds on a
    /// legitimately signed operation.
    @Test
    func testVerifyDigitalSignatureExtension() async throws {
        let op = try await proxy.createOperation()
        let qrData = try await proxy.getQROperation(operationId: op.operationId)
        
        // Parse without automatic verification, then verify manually.
        let qrOp = try WMTQROperationParser().parse(string: qrData.operationQrCodeData).get()
        try pa.verifyDigitalSignature(of: qrOp)
    }
}

// MARK: - Legacy P256 algorithm

/// QR operation parser tests with `PowerAuthAlgorithm.LEGACY_P256`.
/// The legacy algorithm uses ECDSA personalized keys instead of KMAC,
/// so the parsed signature key type must be `.personalized`.
final class QROperationParserLegacyP256IntegrationTests: BaseIntegrationTests {
    
    init() async throws {
        try await super.init(algorithm: .LEGACY_P256)
    }
    
    /// With `LEGACY_P256`, the QR operation is signed with a personalized
    /// ECDSA key. The parser must report `.personalized` key type and the
    /// full authorize + OTP verification flow must succeed.
    @Test
    func testParseWithLegacyP256() async throws {
        let op = try await proxy.createOperation()
        let qrData = try await proxy.getQROperation(operationId: op.operationId)
        
        let parser = WMTQROperationParser(powerAuth: pa)
        let qrOp = try parser.parse(string: qrData.operationQrCodeData).get()
        
        #expect(qrOp.operationId == op.operationId)
        #expect(qrOp.signature.keyType == .personalized, "Legacy P256 should use personalized ECDSA key, not MAC")
        
        let auth = PowerAuthAuthentication.possessionWithPassword(password: pin)
        let otp = try await ops.authorize(qrOperation: qrOp, authentication: auth)
        let verified = try await proxy.verifyQROperation(operationId: op.operationId, operationData: qrData, otp: otp)
        #expect(verified.otpValid, "OTP should be valid for legacy P256 QR operation")
    }
}
