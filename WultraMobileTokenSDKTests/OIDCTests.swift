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
import Testing
@testable import WultraMobileTokenSDK

@Suite(.serialized)
final class OIDCTests {
    
    private let proxy: IntegrationProxy
    private var pa: PowerAuthSDK! { proxy.powerAuth! }
    private var oidc: WMTOIDC! { proxy.wmt!.oidc }
    private let pin = "1234"
    
    init() async throws {
        WMTLogger.verboseLevel = .debug
        proxy = IntegrationProxy()
        try await proxy.prepareForOIDC()
    }
    
    deinit {
        let auth = PowerAuthAuthentication.possessionWithPassword(password: pin)
        let semaphore = DispatchSemaphore(value: 0)
        proxy.powerAuth?.removeActivation(with: auth) { _ in
            semaphore.signal()
        }
        semaphore.wait()
    }

    @Test
    func testGetConfigFails() async throws {
        let nonValidProviderId = "xxx"
        do {
            _ = try await oidc.getConfig(providerId: nonValidProviderId)
            Issue.record("Expected to get error.")
        } catch let err as WMTError {
            #expect(err.httpStatusCode == 400, "Expected to get error.")
        }
    }
    
    @Test
    func testGetConfigSucceed() async throws {
        guard let validProviderId = proxy.getOIDCProviders()?.providerId else {
            WMTLogger.debug("If you want to test OIDC provide a valid providerId in the proxy")
            return
        }
        let config = try await oidc.getConfig(providerId: validProviderId)
        #expect(!config.authorizeUri.isEmpty)
        #expect(!config.providerId.isEmpty)
        #expect(!config.scopes.isEmpty)
        #expect(!config.clientId.isEmpty)
        #expect(!config.redirectUri.isEmpty)
        #expect(config.pkceEnabled == false)
    }
    
    @Test
    func testGetConfigPKCESucceed() async throws {
        guard let validProviderIdPkce = proxy.getOIDCProviders()?.providerIdPkce else {
            WMTLogger.debug("If you want to test OIDC provide a valid providerIdPkce in the proxy")
            return
        }
        let config = try await oidc.getConfig(providerId: validProviderIdPkce)
        #expect(!config.authorizeUri.isEmpty)
        #expect(!config.providerId.isEmpty)
        #expect(!config.scopes.isEmpty)
        #expect(!config.clientId.isEmpty)
        #expect(!config.redirectUri.isEmpty)
        #expect(config.pkceEnabled)
    }
    
    @Test
    func testOIDCPreparesAuthorizationData() async throws {
        guard let providerIdPkce = proxy.getOIDCProviders()?.providerIdPkce else {
            WMTLogger.debug("If you want to test OIDC provide a valid providerIdPkce in the proxy")
            return
        }
        let config = try await oidc.getConfig(providerId: providerIdPkce)
        let authData = oidc.prepareAuthorizationData(config: config)
        switch authData {
        case .success(let data):
            #expect(!config.authorizeUri.isEmpty)
            #expect(!data.state.isEmpty)
            #expect(!data.nonce.isEmpty)
            #expect(data.codeVerifier != nil, "Code verifier should not be null")
        case .failure(let error):
            Issue.record("Authorization Url preparation failed: \(error)")
        }
    }
     
    /// The entire OIDC activation flow is highly dependent on third-party implementations.
    /// This flow was tested using our configuration with `auth0.com`.
    /// Below is a summary of the process outside our system:
    ///
    /// 1. GET request with the authorization URL → Extract the redirect URI and `authState` from the response.
    /// 2. Send a POST request to the login URI with the body containing `username`, `password`, and `authState` → Extract the resume URI from the response.
    /// 3. Send a GET request to the resume URI → Extract the deeplink URI containing the authorization `code`.
    ///
    /// ## Redirect Handling
    /// Unlike typical `URLSession` behavior, where redirects are automatically followed,
    /// this implementation **manually intercepts HTTP redirects** using the `RedirectBlockingSessionDelegate`.
    /// This allows us to capture and process intermediate redirects, making the flow work
    /// even with mixed HTTP methods (e.g., GET → redirect → POST → redirect → GET → redirect).
    ///
    /// ## Testing Requirements
    /// You must also provide the `username` and `password` of your testing Auth0 account
    /// when running this flow. and `providerIdPkce` in the config file
}
