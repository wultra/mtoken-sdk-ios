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
import PowerAuth2
import WultraPowerAuthNetworking

/// Service that communicates with OIDC (OpenID Connect) API
public class WMTOIDC: WMTService {
    
    // Dependencies
    lazy var powerAuth = networking.powerAuth
    let networking: WPNNetworkingService
    
    /// Accept language for the outgoing requests headers.
    public var acceptLanguage: String {
        get { networking.acceptLanguage }
        set { networking.acceptLanguage = newValue }
    }
    
    public init(networking: WPNNetworkingService) {
        self.networking = networking
    }
    
    /// Retrieves configuration based on predefined providerId
    ///
    /// Encrypted with the ECIES application scope.
    /// - Parameters:
    ///   - providerId: Identification of the configuration record, used as a key for the configuration
    ///   - completion: Result completion.
    /// - Returns: Operation to observe
    @discardableResult
    public func getConfig(providerId: String, completion: @escaping (Result<WMTOIDCConfig, WMTError>) -> Void) -> Operation? {
        
        return networking.post(
            data: WMTOIDCEndpoints.Config.EndpointType.RequestData(providerId: providerId),
            to: WMTOIDCEndpoints.Config.endpoint,
            completion: { response, error in
                self.processResult(response: response, error: error, completion: completion)
            }
        )
    }
    
    /// Prepares the OIDC authorization data required for the activation process.
    ///
    /// The function performs the following steps:
    /// 1. Generates PKCE (Proof Key for Code Exchange) codes if PKCE is enabled in the provided configuration.
    /// 2. Creates a `nonce` (a unique value to mitigate replay attacks) and a `state` (to maintain state between the request and callback).
    /// 3. Creates the authorization URL that will be used to open a browser for user authentication.
    ///
    /// - Parameters:
    ///   - config: The OIDC configuration, which includes information about the provider and optional PKCE settings.
    ///
    /// - Returns: A `Result` containing either:
    ///   - On success: `WMTOIDCAuthorizationRequest` with all required data for the authorization process.
    ///   - On failure: `WMTError` with details about what failed.
    public func prepareOIDCAuthorizationData(config: WMTOIDCConfig) -> Result<WMTOIDCAuthorizationRequest, WMTError> {
        do {
            // Using 32 bytes for PKCE code verifiers aligns with RFC 7636 (https://datatracker.ietf.org/doc/html/rfc7636).
            // For nonce and state, OpenID Connect does not specify a strict length, but 32 bytes ensures strong randomness to prevent replay and CSRF attacks.
            let pkceCodes = config.pkceEnabled ? try WMTOIDCUtils.createPKCE(dataLength: 32) : nil
            let nonce = try WMTOIDCUtils.getRandomBase64UrlSafe(dataLength: 32)
            let state = try WMTOIDCUtils.getRandomBase64UrlSafe(dataLength: 32)

            let authorizeUrl = try WMTOIDCUtils.createAuthorizationUrl(config: config, nonce: nonce, state: state, pkceCodes: pkceCodes)
                return .success(
                    WMTOIDCAuthorizationRequest(
                        authorizeUrl: authorizeUrl,
                        providerId: config.providerId,
                        nonce: nonce,
                        state: state,
                        codeVerifier: pkceCodes?.codeVerifier
                    )
                )
            
        } catch let error as WMTError {
            D.error("OIDC: Authorization Data creation failed: \(error)")
            return .failure(.wrap(error.reason, error))
        } catch {
            D.error("OIDC: Authorization Data creation failed: \(error)")
            return .failure(.wrap(.unknown, error))
        }
    }
}
