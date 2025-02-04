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

/// Utility class for OIDC
public class WMTOidcUtils {
    
    /// Creates PKCE codes, returning a Result wrapping the codes.
    public static func createPKCE(dataLength: Int) throws -> WMTPKCECodes {
        let minLength: Int = 32 // min is 32-octet sequence == Base64 43 URL safe characters
        let maxLength: Int = 96 // max is 96-octet sequence == Base64 128 URL safe characters
        let length = (dataLength > minLength && dataLength < maxLength) ? dataLength : minLength
        
        let codeVerifier = try getRandomBase64UrlSafe(dataLength: length)
        let codeChallenge = try generateCodeChallenge(verifier: codeVerifier)
        return WMTPKCECodes(codeVerifier: codeVerifier, codeChallenge: codeChallenge)
    }

    /// Generates a random Base64 URL-safe string of the given length.
    public static func getRandomBase64UrlSafe(dataLength: Int) throws -> String {
        var randomBytes = [Int8](repeating: 0, count: dataLength)
        
        // Fill bytes with secure random data
        let status = SecRandomCopyBytes(kSecRandomDefault, dataLength, &randomBytes)
        
        // A status of errSecSuccess indicates success
        guard status == errSecSuccess else { throw WMTError(reason: .randomBytesFailed) }
        
        // Convert bytes to Data
        let data = Data(bytes: randomBytes, count: dataLength)
        return data.base64EncodedString().safeUrlString
    }
    
    /// Creates an authorization URL.
    public static func createAuthorizationUrl(config: WMTOidcConfig, nonce: String, state: String, pkceCodes: WMTPKCECodes?) throws -> URL {
        guard var components = URLComponents(string: config.authorizeUri) else {
            D.warning("OIDC: auth url is malformed")
            throw WMTError(reason: .authorizationUrlCreationFailed)
        }
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "redirect_uri", value: config.redirectUri),
            URLQueryItem(name: "scope", value: config.scopes),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "nonce", value: nonce),
            URLQueryItem(name: "response_type", value: "code")
        ]
        
        if let pkceCodes {
            components.queryItems?.append(URLQueryItem(name: "code_challenge", value: pkceCodes.codeChallenge))
            components.queryItems?.append(URLQueryItem(name: "code_challenge_method", value: pkceCodes.codeMethod))
        }
        
        if let url = components.url {
            D.debug("OIDC: Successfully created auth URL: \(url.absoluteString)")
            return url
        } else {
            D.warning("OIDC: Failed to create URL.")
            throw WMTError(reason: .authorizationUrlCreationFailed)
        }
    }
    
    /// Processes a deeplink URI to validate its state and extract OIDC activation attributes.
    ///
    /// - Parameters:
    ///   - url: The deeplink URL received from the OIDC provider during the authorization process.
    ///   - oidcAuthorizationData: Data containing the necessary data for the OIDC flow.
    ///
    /// - Returns: A `WMTOidcPowerAuthActivationAttributes` attributes needed for OIDC PowerAuth activation flow
    /// - Throws: An error when attributes cannot be constructed.
    public static func processWebCallback(from url: URL, with oidcAuthorizationData: WMTOidcAuthorizationRequest) throws -> WMTOidcPowerAuthActivationAttributes {
        
        guard let queryItems = URLComponents(string: url.absoluteString)?.queryItems else {
            D.error("OIDC: Invalid callback URL: \(url)")
            throw WMTError(reason: .invalidDeeplink)
        }
        
        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            D.error("OIDC: Code not found in response from URL: \(url)")
            throw WMTError(reason: .invalidDeeplink)
        }
        
        guard let state = queryItems.first(where: { $0.name == "state" })?.value else {
            D.error("OIDC: State not found in response from URL: \(url)")
            throw WMTError(reason: .invalidDeeplink)
        }
        
        guard state == oidcAuthorizationData.state else {
            D.error("OIDC: Invalid 'state' in URL: \(url)")
            throw WMTError(reason: .invalidDeeplink)
        }
        
        return WMTOidcPowerAuthActivationAttributes(
            providerId: oidcAuthorizationData.providerId,
            code: code,
            nonce: oidcAuthorizationData.nonce,
            codeVerifier: oidcAuthorizationData.codeVerifier
        )
    }
    
    /// PKCE Helper
    /// Helper: Generates a SHA-256-based code challenge.
    private static func generateCodeChallenge(verifier: String) throws -> String {
        guard let verifierData = verifier.data(using: .ascii) else { throw WMTError(reason: .codeChallengeGenerationFailed ) }
        let challengeHashed = verifierData.sha256()
        return challengeHashed.base64EncodedString().safeUrlString
    }
}
