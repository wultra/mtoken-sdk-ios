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


import XCTest
import PowerAuth2
@testable import WultraMobileTokenSDK

final class OIDCTests: XCTestCase {
    
    private var proxy: IntegrationProxy!
    private var pa: PowerAuthSDK? { proxy.powerAuth }
    private var oidc: WMTOIDC? { proxy.wmt?.oidc }
    private let pin = "1234"
    
    override func setUp() {
        super.setUp()
        WMTLogger.verboseLevel = .debug
        proxy = IntegrationProxy()
        
        let exp = XCTestExpectation(description: "setup expectation")
        
        // Integration Utils prepares OIDC service
        proxy.prepareForOIDC() { error in
            if let error = error {
                XCTFail(error)
            }
            exp.fulfill()
        }
        
        let waiter = XCTWaiter()
        waiter.wait(for: [exp], timeout: 20)
    }
    
    override func tearDown() {
        super.tearDown()
        let exp = XCTestExpectation(description: "setup expectation")
        
        // after each batch of tests, remove the activation
        let auth = PowerAuthAuthentication.possessionWithPassword(password: pin)
        if let pa = pa {
            pa.removeActivation(with: auth) { err in
                exp.fulfill()
            }
        }
        
        let waiter = XCTWaiter()
        waiter.wait(for: [exp], timeout: 20)
    }

    func testGetConfigFails() {
        let nonValidProviderId = "xxx"
        let exp = expectation(description: "Failed providerId config expectation")
        
        _ = oidc?.getConfig(providerId: nonValidProviderId, completion: { result in
            switch result {
            case .success(let config):
                XCTAssertNil(config)
            case .failure(let err):
                XCTAssertTrue(err.httpStatusCode == 400, "Expected to get error.")
            }
            exp.fulfill()
        })
        
        waitForExpectations(timeout: 20, handler: nil)
    }
    
    func testGetConfigSucceed() {
        guard let validProviderId = proxy.getOIDCProviders()?.providerId else {
            WMTLogger.debug("If you want to test OIDC provide a valid providerId in the proxy")
            return
        }
        let exp = expectation(description: "Valid providerId config expectation")
        
        
        _ = oidc?.getConfig(providerId: validProviderId, completion: { result in
            switch result {
            case .success(let config):
                XCTAssertNotNil(config.authorizeUri)
                XCTAssertNotNil(config.providerId)
                XCTAssertNotNil(config.scopes)
                XCTAssertNotNil(config.clientId)
                XCTAssertNotNil(config.redirectUri)
                XCTAssertTrue(config.pkceEnabled == false)
            case .failure(let err):
                XCTFail("OIDC config request failed: \(err)")
            }
            exp.fulfill()
        })
        
        waitForExpectations(timeout: 20, handler: nil)
    }
    
    func testGetConfigPKCESucceed() {
        guard let validProviderIdPkce = proxy.getOIDCProviders()?.providerIdPkce else {
            WMTLogger.debug("If you want to test OIDC provide a valid providerIdPkce in the proxy")
            return
        }
        let exp = expectation(description: "Valid providerId config expectation")
        
        
        _ = oidc?.getConfig(providerId: validProviderIdPkce, completion: { result in
            switch result {
            case .success(let config):
                XCTAssertNotNil(config.authorizeUri)
                XCTAssertNotNil(config.providerId)
                XCTAssertNotNil(config.scopes)
                XCTAssertNotNil(config.clientId)
                XCTAssertNotNil(config.redirectUri)
                
                XCTAssertTrue(config.pkceEnabled)
            case .failure(let err):
                XCTFail("OIDC config request failed: \(err)")
            }
            exp.fulfill()
        })
        
        waitForExpectations(timeout: 20, handler: nil)
    }
    
    func testOIDCPreparesAuthorizationData() {
        guard let providerIdPkce = proxy.getOIDCProviders()?.providerIdPkce else {
            WMTLogger.debug("If you want to test OIDC provide a valid providerIdPkce in the proxy")
            return
        }
        
        guard let oidc = self.oidc else {
            XCTFail("OIDC must not be nil!")
            return
        }
        
        let exp = expectation(description: "Auth data preparation expectation")
        
        _ = oidc.getConfig(providerId: providerIdPkce, completion: { result in
            switch result {
            case .success(let config):
                XCTAssertNotNil(config)
                
                let authData = oidc.prepareOIDCAuthorizationData(config: config)
                switch authData {
                case .success(let data):
                    
                    
                    XCTAssertNotNil(data.authorizeUrl, "Authorization URI should not be null")
                    XCTAssertNotNil(data.state, "State should not be nil")
                    XCTAssertNotNil(data.nonce, "Nonce should not be nil")
                    XCTAssertNotNil(data.codeVerifier, "Code verifier should not be null")
                    
                case .failure(let error):
                    XCTFail("Authorization Url preparation failed: \(error)")
                }
                
                
            case .failure(let err):
                XCTFail("OIDC config request failed: \(err)")
            }
            exp.fulfill()
        })
        
        waitForExpectations(timeout: 20, handler: nil)
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
//    func testOIDCActivationFlow() {
//        // Define test credentials
//        let username = "wultra@example.com"
//        let password = "nzp9ufu*FAD@ztf.hab"
//
//        guard let oidc = self.oidc,
//              let providerIdPkce = proxy.getOIDCProviders()?.providerIdPkce else {
//            XCTFail("OIDC and providerIdPkce must not be nil!")
//            return
//        }
//
//        // Fetch OIDC Configuration
//        guard let config = fetchOIDCConfig(oidc: oidc, providerIdPkce: providerIdPkce) else {
//            XCTFail("Failed to fetch OIDC configuration")
//            return
//        }
//
//        // Prepare OIDC Authorization Data
//        guard let oidcAuthData = prepareOIDCAuthorizationData(oidc: oidc, config: config) else {
//            XCTFail("Failed to prepare OIDC authorization data")
//            return
//        }
//
//        // Perform Login
//        do {
//            guard let redirectUri = try loginWithAuth0(oidcAuthData.authorizeUrl, username: username, password: password) else {
//                XCTFail("Failed to get redirect URI after login")
//                return
//            }
//
//            // Process Redirect URI
//            let activationAttributes = try WMTOIDCUtils.processWebCallback(from: redirectUri, with: oidcAuthData)
//
//            // Create PowerAuth Activation
//            createPowerAuthActivation(activationAttributes: activationAttributes)
//        } catch {
//            XCTFail("Test failed with exception: \(error.localizedDescription)")
//        }
//    }
//
//    // Helpers
//    private func fetchOIDCConfig(oidc: WMTOIDC, providerIdPkce: String) -> WMTOIDCConfig? {
//        let expectation = XCTestExpectation(description: "Fetch OIDC configuration")
//        var config: WMTOIDCConfig?
//
//        oidc.getConfig(providerId: providerIdPkce) { result in
//            if case .success(let fetchedConfig) = result {
//                config = fetchedConfig
//                expectation.fulfill()
//            } else if case .failure(let error) = result {
//                XCTFail("Failed to fetch OIDC configuration: \(error.localizedDescription)")
//            }
//        }
//
//        wait(for: [expectation], timeout: 20.0)
//        return config
//    }
//
//    private func prepareOIDCAuthorizationData(oidc: WMTOIDCService, config: WMTOIDCConfig) -> WMTOIDCAuthorizationRequest? {
//        let expectation = XCTestExpectation(description: "Prepare OIDC authorization data")
//        var authData: WMTOIDCAuthorizationRequest?
//
//        let result = oidc.prepareOIDCAuthorizationData(config: config, callbackScheme: "mtoken")
//        if case .success(let data) = result {
//            authData = data
//            expectation.fulfill()
//        } else if case .failure(let error) = result {
//            XCTFail("Failed to prepare OIDC authorization data: \(error.localizedDescription)")
//        }
//
//        wait(for: [expectation], timeout: 5.0)
//        return authData
//    }
//
//    private func createPowerAuthActivation(activationAttributes: WMTOIDCPowerAuthActivationAttributes) {
//        let expectation = XCTestExpectation(description: "Create PowerAuth activation")
//        do {
//            try pa?.createOIDCActivation(attributes: activationAttributes, deviceName: "iOS Test") { result in
//                if case .success(let activationResult) = result {
//                    XCTAssertNotNil(activationResult, "Activation result should not be nil")
//                    expectation.fulfill()
//                } else if case .failure(let error) = result {
//                    XCTFail("Failed to create PowerAuth activation: \(error.localizedDescription)")
//                }
//            }
//        } catch {
//            XCTFail("Failed to create PowerAuth activation: \(error.localizedDescription)")
//        }
//
//
//        wait(for: [expectation], timeout: 20.0)
//    }
//
//    private func loginWithAuth0(_ authorizeUrl: URL, username: String, password: String) throws -> URL? {
//        let session = createSession()
//        var deeplinkUrl: URL?
//        let semaphore = DispatchSemaphore(value: 0)
//        var capturedError: Error?
//
//        // 1. authorize request
//        performRequest(session: session, url: authorizeUrl, method: "GET", body: nil) { redirectUrl, authState, error in
//            if let error = error {
//                capturedError = error
//                semaphore.signal()
//                return
//            }
//
//            guard let authRedirectUrl = redirectUrl else {
//                capturedError = NSError(domain: "LoginFlow", code: 0, userInfo: [NSLocalizedDescriptionKey: "Redirect URL not found."])
//                semaphore.signal()
//                return
//            }
//
//            // User is already logged in if redirect URL contains `code`
//            if authRedirectUrl.absoluteString.contains("code") {
//                deeplinkUrl = authRedirectUrl
//                semaphore.signal()
//                return
//            }
//
//            guard let authState = authState else {
//                capturedError = NSError(domain: "LoginFlow", code: 0, userInfo: [NSLocalizedDescriptionKey: "State parameter not found."])
//                semaphore.signal()
//                return
//            }
//
//            // 2. login request
//            let loginBody = "username=\(username)&password=\(password)&state=\(authState)"
//            self.performRequest(session: session, url: authRedirectUrl, method: "POST", body: loginBody) { loginRedirectUrl, _, error in
//                if let error = error {
//                    capturedError = error
//                    semaphore.signal()
//                    return
//                }
//
//                guard let loginRedirectUrl = loginRedirectUrl else {
//                    capturedError = NSError(domain: "LoginFlow", code: 0, userInfo: [NSLocalizedDescriptionKey: "Final redirect URI not found after login."])
//                    semaphore.signal()
//                    return
//                }
//
//                // 3. resume request to get the redirect deeplink URL
//                self.performRequest(session: session, url: loginRedirectUrl, method: "GET", body: nil) { resumeRedirectUrl, _, error in
//                    if let error = error {
//                        capturedError = error
//                    } else {
//                        deeplinkUrl = resumeRedirectUrl
//                    }
//                    semaphore.signal()
//                }
//            }
//        }
//
//        semaphore.wait()
//        if let error = capturedError { throw error }
//        return deeplinkUrl
//    }
//
//    private func performRequest(session: URLSession, url: URL, method: String, body: String?, completion: @escaping (URL?, String?, Error?) -> Void) {
//        var request = URLRequest(url: url)
//        request.httpMethod = method
//        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
//
//        if let body = body, method == "POST" {
//            request.httpBody = body.data(using: .utf8)
//        }
//
//        let task = session.dataTask(with: request) { data, response, error in
//            if let error = error {
//                completion(nil, nil, error)
//                return
//            }
//
//            guard let httpResponse = response as? HTTPURLResponse else {
//                completion(nil, nil, NSError(domain: "LoginFlow", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response URL."]))
//                return
//            }
//            
//            guard let scheme = url.scheme,
//                  let host = url.host,
//                  let locationHeader = httpResponse.allHeaderFields["Location"] as? String,
//                  let redirectUrl = URL(string: "\(scheme)://\(host)\(locationHeader)")
//            else {
//                D.debug("Failed to construct redirect URL from authorizeUrl and Location header")
//                return
//            }
//            
//            // if location header contains code it means that we have our deeplinkUrl
//            if locationHeader.contains("code"), let deeplinkUrl = URL(string: locationHeader) {
//                D.debug("Found code, deeplink URL is: \(deeplinkUrl)")
//                completion(deeplinkUrl, nil, nil)
//                return
//            }
//
//            // Extract `state` from the response URL
//            var authState: String? = nil
//            if let components = URLComponents(url: redirectUrl, resolvingAgainstBaseURL: false),
//               let state = components.queryItems?.first(where: { $0.name == "state" }) {
//                authState = state.value
//            }
//
//            D.debug("Redirect URL is: \(redirectUrl)")
//            completion(redirectUrl, authState, nil)
//        }
//
//        task.resume()
//    }
//    
//    private func createSession() -> URLSession {
//        let config = URLSessionConfiguration.default
//        config.httpCookieStorage = HTTPCookieStorage.shared // Store cookies
//        config.httpCookieAcceptPolicy = .always
//        config.httpShouldSetCookies = true
//        config.httpAdditionalHeaders = [
//            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)",
//            "Accept-Language": "en-US,en;q=0.9"
//        ]
//        return URLSession(configuration: config, delegate: RedirectBlockingSessionDelegate(), delegateQueue: nil)
//    }
//    
//    // we need to intercept the redirect
//    class RedirectBlockingSessionDelegate: NSObject, URLSessionTaskDelegate {
//        func urlSession(_ session: URLSession,
//                        task: URLSessionTask,
//                        willPerformHTTPRedirection response: HTTPURLResponse,
//                        newRequest request: URLRequest,
//                        completionHandler: @escaping (URLRequest?) -> Void) {
//            
//            D.debug("Intercepted Redirect: \(response.url?.absoluteString ?? "Unknown")")
//            
//            // Instead of following the redirect, we return `nil` to stop it.
//            completionHandler(nil)
//        }
//    }
}
