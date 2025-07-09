//
// Copyright 2025 Wultra s.r.o.
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
import CommonCrypto
import PowerAuth2

public extension PowerAuthSDK {
    /// Creates PowerAuth activation based on the data in the `WMTOIDCPowerAuthActivationAttributes` object.
    ///
    /// - Parameters:
    ///   - attributes: A `WMTOIDCPowerAuthActivationAttributes` object containing the information required for the activation creation.
    ///                 Includes `providerId`, `code`, `nonce`, and optional `codeVerifier`.
    ///   - deviceName: The `deviceName` is activation's name parameter and it is optional, but recommended to set. You can use the value obtained from
    ///                 `UIDevice.current.name` or let the user set the name. The name of activation will be associated with
    ///                 an activation record on PowerAuth Server.
    ///   - callback: A completion callback that is invoked when the activation process finishes.
    ///               - On success: Returns a `PowerAuthActivationResult` containing the activation fingerprint.
    ///               - On failure: Returns an `Error` describing the issue.
    ///
    /// - Returns: A `PowerAuthOperationTask?` representing the operation, which can be used to cancel the request if needed.
    /// - Throws: An error when activation data cannot be constructed.
    /// - more info at https://developers.wultra.com/components/powerauth-mobile-sdk/develop/documentation/PowerAuth-SDK-for-iOS.html#activation-via-openid-connect
    @discardableResult
    func createOIDCActivation(
        attributes: WMTOIDCPowerAuthActivationAttributes,
        activationName: String? = nil,
        _ callback: @escaping (Result<PowerAuthActivationResult, Error>) -> Void
    ) throws -> PowerAuthOperationTask? {
        var activation = try PowerAuthActivation(
            oidcProviderId: attributes.providerId,
            code: attributes.code,
            nonce: attributes.nonce,
            codeVerifier: attributes.codeVerifier
        )
        
        if let activationName = activationName {
            activation = activation.with(activationName: activationName)
        }
        
        return createActivation(activation) { result, error in
            if let result = result {
                callback(.success(result))
            } else {
                D.error("OIDC: Actication failed with error: \(String(describing: error))")
                callback(.failure( (error != nil) ? .wrap(.oidc_activationFailed, error) : WMTError(reason: .oidc_activationFailed)))
            }
        }
    }
}

extension String {
    /// A computed property to transform a Base64-encoded string into a URL-safe.
    ///
    /// The default Base64 encoding in Swift uses `+` and `/` at positions 62 and 63, which are not safe for URLs.
    /// RFC 4648 defines a URL-safe Base64 variant that replaces `+` with `-`, `/` with `_`, and removes `=` padding.
    /// This transformation ensures compatibility with URL query parameters.
    var safeOIDCUrlString: String {
        self
            .replacingOccurrences(of: "=", with: "") // Remove any trailing '='s
            .replacingOccurrences(of: "+", with: "-") // 62nd char of encoding
            .replacingOccurrences(of: "/", with: "_") // 63rd char of encoding
            .trimmingCharacters(in: .whitespaces)
    }
}

extension Data {
    /// Computes SHA-256 hash of the data.
    func sha256() -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes { bytes in
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(self.count), &hash)
        }
        return Data(hash)
    }
}
