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

/// Allowed signature types that can be used for operation approval.
public class WMTAllowedOperationSignature: Codable {
    
    /// If operation should be signed with 1 or 2 factor authentication
    public let signatureType: SignatureType
    
    /// What factors ("password" or/and "biometry") can be used for signing this operation.
    public let signatureFactors: [SignatureFactors]
    
    /// Helper getter if biometry factor is allowed.
    public var isBiometryAllowed: Bool { return signatureFactors.contains(.possessionBiometry) }
    
    // MARK: - INNER CLASSES
    
    public enum SignatureType: String, Codable {
        case singleFactor = "1FA"
        case twoFactors = "2FA"
    }
    
    public enum SignatureFactors: String, Codable {
        case possessionKnowledge = "possession_knowledge"
        case possessionBiometry = "possession_biometry"
    }
    
    // MARK: - INTERNALS
    
     public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        signatureType = try c.decode(SignatureType.self, forKey: .signatureType)
        signatureFactors = try c.decode([SignatureFactors].self, forKey: .signatureFactors)
    }
    
    public init(signatureType: SignatureType, signatureFactors: [SignatureFactors]) {
        self.signatureType = signatureType
        self.signatureFactors = signatureFactors
    }
    
    private enum Keys: String, CodingKey {
        case signatureType = "type"
        case signatureFactors = "variants"
    }
}
