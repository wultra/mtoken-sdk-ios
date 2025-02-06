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

// MARK: - PowerAuthSDK quick-access extension

public extension PowerAuthSDK {
    
    /// Creates Wultra Mobile Token services from on top of the `PowerAuthSDK`.
    /// URL from the `PowerAuthSDK` instance is used for services.
    ///
    /// `PowerAuthSDK` instance. Needs to be activated when calling any method of this class; otherwise, an error will be thrown.
    /// - Parameters:
    ///   - acceptLanguage: The language code to set for the `Accept-Language` header.  "en" when nil.
    ///   - userAgent: User agent that will be used in a HTTP header. Default library value when nil.
    /// - Returns: Mobile Token SDK main wrapper.
    /// - Throws: `InitError` when the object cannot be instantiated (incorrent URL).
    func createWultraMobileToken(acceptLanguage: String? = nil, userAgent: WPNUserAgent? = nil) throws -> WultraMobileToken {
       return try WultraMobileToken(powerAuth: self, acceptLanguage: acceptLanguage, userAgent: userAgent)
    }
}

// MARK: - Main Class

 /// `WultraMobileToken` provides lazy loaded core services of the SDK:
 /// `operations`, `push` and `inbox`.
public class WultraMobileToken {
    
    // MARK: Private fields
    
    // PowerAuth instance
    private let powerAuth: PowerAuthSDK
    // Networking config
    private let wpnConfig: WPNConfig
    // Accept language backing field
    private var acceptLanguage: String
    
    // Lazy-loaded backing fields
    private lazy var operationsBacking = WMTLazy(
        WMTOperations(
            networking: WPNNetworkingService(
                powerAuth: self.powerAuth,
                config: self.wpnConfig,
                serviceName: "WMTOperations",
                acceptLanguage: self.acceptLanguage
            )
        )
    )
    private lazy var pushBacking = WMTLazy(
        WMTPush(
            networking: WPNNetworkingService(
                powerAuth: self.powerAuth,
                config: self.wpnConfig,
                serviceName: "WMTPush",
                acceptLanguage: self.acceptLanguage
            )
        )
    )
    private lazy var inboxBacking = WMTLazy(
        WMTInbox(
            networking: WPNNetworkingService(
                powerAuth: self.powerAuth,
                config: self.wpnConfig,
                serviceName: "WMTInbox",
                acceptLanguage: self.acceptLanguage
            )
        )
    )
    
    private lazy var oidcBacking = WMTLazy(
        WMTOIDC(
            networking: WPNNetworkingService(
                powerAuth: self.powerAuth,
                config: self.wpnConfig,
                serviceName: "WMTOIDC",
                acceptLanguage: self.acceptLanguage
            )
        )
    )
    
    // MARK: Public API
    
    /// Initializes a new instance of `WultraMobileToken`. Which may fail if the PowerAuth `baseEndpointUrl` is invalid
    /// - Parameters:
    ///   - powerAuth: `PowerAuthSDK` instance. Needs to be activated when calling any method of this class; otherwise, an error will be thrown.
    ///   - acceptLanguage: The language code to set for the `Accept-Language` header.  "en" when nil.
    ///   - userAgent: User agent that will be used in a HTTP header. Default library value when nil.
    /// - Throws: `InitError` when the object cannot be instantiated (incorrent URL).
    public init(
        powerAuth: PowerAuthSDK,
        acceptLanguage: String? = nil,
        userAgent: WPNUserAgent? = nil
    ) throws {
        self.powerAuth = powerAuth
        self.acceptLanguage = acceptLanguage ?? "en"
        guard let url = URL(string: powerAuth.configuration.baseEndpointUrl) else {
            throw InitError.invalidBaseURL(url: powerAuth.configuration.baseEndpointUrl)
        }
        self.wpnConfig = WPNConfig(baseUrl: url, userAgent: userAgent ?? .libraryDefault)

        D.debug("Default Wultra Mobile Token object created with:")
        D.debug(" - baseURL: \(powerAuth.configuration.baseEndpointUrl)")
    }
    
    /// Operations manager. Use for fetching pending lists, approving operations, etc.
    public var operations: WMTOperations { operationsBacking.lazy }
    
    /// Push manager for registering the device to receive PowerAuth push notifications for a given PowerAuth activation.
    public var push: WMTPush { pushBacking.lazy }
    
    /// Inbox manager - receives messages to communicate with the user.
    public var inbox: WMTInbox { inboxBacking.lazy }
    
    /// OIDC manager - receive the config and help with OIDC activation preparation
    public var oidc: WMTOIDC { oidcBacking.lazy }
    
    /**
     Sets the accept language for the outgoing request headers for `operations`, `push`, and `inbox` objects.
     
     The value can be further modified in each object individually.
     
     **Standard RFC "Accept-Language"**: [RFC 7231, Section 5.3.5](https://tools.ietf.org/html/rfc7231#section-5.3.5)
     
     Response texts are based on this setting. For example, when `de` is set, the server
     will return operation texts in German (if available).
     
     - Parameter lang: The language code to set for the `Accept-Language` header.
     */
    public func setAcceptLanguage(_ lang: String) {
        acceptLanguage = lang
        operationsBacking.optional?.acceptLanguage = lang
        pushBacking.optional?.acceptLanguage = lang
        inboxBacking.optional?.acceptLanguage = lang
        oidcBacking.optional?.acceptLanguage = lang
        D.info("Accept language set to \(lang)")
    }
    
    /// Initializer error
    public enum InitError: LocalizedError {
        /// Provided URL is invalid (see `url` associated value)
        case invalidBaseURL(url: String)
        
        public var errorDescription: String? {
            switch self {
            case .invalidBaseURL(let url): return "invalidBaseURL: Provided URL is invalid: \(url)"
            }
        }
    }
}
