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

/// The `WMTQROperationData` contains data operation data parsed from QR code.
public struct WMTQROperation {
    
    /// Operation's identifier
    public let operationId: String
    
    /// Title associated with the operation.
    public let title: String
    
    /// Message associated with the operation
    public let message: String
    
    /// Significant data fields associated with the operation
    public let operationData: WMTQROperationData
    
    /// Nonce for offline signature calculation, in Base64 format
    public let nonce: String
    
    /// Flags associated with the operation
    public let flags: QROperationFlags
    
    /// Data for signature validation
    public let signedData: Data
    
    /// ECDSA signature calculated from `signedData`. String is in Base64 format
    public let signature: WMTQROperationSignature
    
    /// QR code uses a string in newer format that this class implements.
    /// This flag may be used as warning, presented in UI
    public let isNewerFormat: Bool
    
    internal var nonceForOfflineSigning: String {
        return nonce
    }
    
    internal var uriIdForOfflineSigning: String {
        return "/operation/authorize/offline"
    }
    
    internal var dataForOfflineSigning: Data {
        return "\(operationId)&\(operationData.sourceString)".data(using: .utf8)!
    }
}

public struct WMTQROperationSignature {
    /// The enumeration defines which key was used for ECDSA signature calculation
    public enum SigningKey {
        /// Master server key was used for ECDSA signature calculation
        case master
        /// Personalized server's private key was used for ECDSA signature calculation
        case personalized
    }
    
    /// Defines which key has been used for ECDSA signature calculation.
    public let signingKey: SigningKey
    
    /// Signature in Base64 format
    public let signature: String
}


/// The `WMTQROperationFlags` structure defines flags associated with the operation
public struct QROperationFlags {
    
    /// If true, then 2FA signature with biometry factor can be used for operation confirmation.
    public let allowBiometryFactor: Bool
}


/// The `WMTQROperationData` structure defines operation data in QR operation.
public struct WMTQROperationData {
    
    public enum Version: Character {
        /// First version of operation data
        case v1 = "A"
        /// Type representing all newer versions of operation data
        /// (for forward compatibility)
        case vX = "*"
    }
    
    /// The `Field` enumeration defines field types available in operation data.
    public enum Field {
        
        /// Amount with currency
        case amount(amount: Decimal, currency: String)
        
        /// Account in IBAN format, with optional BIC
        case account(iban: String, bic: String?)
        
        /// Account in arbitrary textual format
        case anyAccount(account: String)
        
        /// Date field
        case date(date: Date)
        
        /// Reference field
        case reference(text: String)
        
        /// Note field
        case note(text: String)
        
        /// Text field
        case text(text: String)
        
        /// Fallback for forward compatibility. If newer version of operation data
        /// contains new field type, then this case can be used for it's
        /// representation
        case fallback(text: String, fieldType: Character)
        
        /// Reserved for optional and not used fields
        case empty
    }
    
    /// Version of form data
    public let version: Version
    
    /// Template identifier (0 .. 99 in v1)
    public let templateId: Int
    
    /// Array with form fields. Version v1 supports up to 5 fields.
    public let fields: [Field]
    
    /// A whole line from which was this structure constructed.
    public let sourceString: String
}
