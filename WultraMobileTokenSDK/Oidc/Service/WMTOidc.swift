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
public class WMTOidc: WMTService {
    
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
    public func getConfig(providerId: String, completion: @escaping (Result<WMTOidcConfig, WMTError>) -> Void) -> Operation? {
        
        return networking.post(
            data: OidcEndpoints.Config.EndpointType.RequestData(providerId: providerId),
            to: OidcEndpoints.Config.endpoint,
            completion: { response, error in
                self.processResult(response: response, error: error, completion: completion)
            }
        )
    }
    
    /// Prepares the OIDC authorization data required for the activation process.
    ///
    /// The function performs the following steps:
    /// 1. Verifies and retrieves the callback scheme for the authorization process.
    /// 2. Generates PKCE (Proof Key for Code Exchange) codes if PKCE is enabled in the provided configuration.
    /// 3. Creates a `nonce` (a unique value to mitigate replay attacks) and a `state` (to maintain state between the request and callback).
    /// 4. Creates the authorization URL that will be used to open a browser for user authentication.
    ///
    /// - Parameters:
    ///   - config: The OIDC configuration, which includes information about the provider and optional PKCE settings.
    ///
    /// - Returns: A `Result` containing either:
    ///   - On success: `WMTOidcAuthorizationRequest` with all required data for the authorization process.
    ///   - On failure: `WMTError` with details about what failed.
    public func prepareOidcAuthorizationData(config: WMTOidcConfig) -> Result<WMTOidcAuthorizationRequest, WMTError> {
        do {
            let pkceCodes = try createPkce(enabled: config.pkceEnabled, dataLength: 32)
            let nonce = try WMTOidcUtils.getRandomBase64UrlSafe(dataLength: 32)
            let state = try WMTOidcUtils.getRandomBase64UrlSafe(dataLength: 32)

            let authorizeUrl = try WMTOidcUtils.createAuthorizationUrl(config: config, nonce: nonce, state: state, pkceCodes: pkceCodes)
                return .success(
                    WMTOidcAuthorizationRequest(
                        authorizeUrl: authorizeUrl,
                        callbackScheme: config.redirectUri,
                        providerId: config.providerId,
                        nonce: nonce,
                        state: state,
                        codeVerifier: pkceCodes?.codeVerifier
                    )
                )
            
        } catch let error as WMTError {
            D.error("Oidc: Authorization Data creation failed: \(error)")
            return .failure(.wrap(error.reason, error))
        } catch {
            D.error("Oidc: Authorization Data creation failed: \(error)")
            return .failure(.wrap(.unknown, error))
        }
    }
    
    /// Helper method to return Result nil if PKCE is not enabled
    private func createPkce(enabled: Bool, dataLength: Int) throws -> WMTPKCECodes? {
        if enabled == false {
            return nil
        } else {
            return try WMTOidcUtils.createPKCE(dataLength: dataLength)
        }
    }
}
