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

public extension PowerAuthSDK {
    func createWultraMobileToken(
        acceptLanguage: String = "en",
        userAgent: WPNUserAgent = .libraryDefault
    ) throws -> WultraMobileToken {
       return try WultraMobileToken(powerAuth: self, acceptLanguage: acceptLanguage, userAgent: userAgent)
    }
}

 /// `WultraMobileToken` class exposes APIs that enable fetching, authorizing, or rejecting basic
 ///  operations created in the PowerAuth stack.
public class WultraMobileToken {
    
    /// Operations manager. Use for fetching pending lists, approving operations, etc.
    public lazy var operations: WMTOperations = createOperations()
    
    /// Push manager for registering the device to receive PowerAuth push notifications for a given PowerAuth activation.
    public lazy var push: WMTPush = createPush()
    
    /// Inbox manager - receives messages to communicate with the user.
    public lazy var inbox: WMTInbox = createInbox()
    
    /// PowerAuth Instance
    private let powerAuth: PowerAuthSDK
    /// User-Agent header.
    private let userAgent: WPNUserAgent?
    /// Base URL for service requests.
    private let baseURL: URL
    
    /// Accept language for the outgoing requests headers.
    /// Default value is "en".
    ///
    /// Standard RFC "Accept-Language" https://tools.ietf.org/html/rfc7231#section-5.3.5
    /// Response texts are based on this setting. For example when "de" is set, server
    /// will return operation texts in german (if available).
    /// To change its value use method `setAcceptLanguage("en")`
    private var acceptLanguage: String
    
    /// Initializes a new instance of `WultraMobileToken`. Which may fail if the PowerAuth `baseEndpointUrl` is invalid
    /// - Parameters:
    ///   - powerAuth: `PowerAuth` instance. Needs to be activated when calling any method of this class; otherwise, an error will be thrown.
    ///   - acceptLanguage: The language code to set for the `Accept-Language` header.
    ///   - userAgent: User agent that will be used in a HTTP header.
    public init(
        powerAuth: PowerAuthSDK,
        acceptLanguage: String = "en",
        userAgent: WPNUserAgent = .libraryDefault
    ) throws {
        self.powerAuth = powerAuth
        self.acceptLanguage = acceptLanguage
        self.userAgent = userAgent
        self.baseURL = try Self.resolveURL(from: powerAuth.configuration.baseEndpointUrl)

        D.debug("Default Wultra Mobile Token object created with:")
        D.debug(" - baseURL: \(powerAuth.configuration.baseEndpointUrl)")
    }
    
    /**
     Sets the accept language for the outgoing request headers for `operations`, `push`, and `inbox` objects.
     
     The value can be further modified in each object individually.
     
     **Standard RFC "Accept-Language"**: [RFC 7231, Section 5.3.5](https://tools.ietf.org/html/rfc7231#section-5.3.5)
     
     Response texts are based on this setting. For example, when `"de"` is set, the server
     will return operation texts in German (if available).
     
     - Parameter lang: The language code to set for the `Accept-Language` header.
     */
    public func setAcceptLanguage(_ lang: String) {
        acceptLanguage = lang
        operations.acceptLanguage = lang
        push.acceptLanguage = lang
        inbox.acceptLanguage = lang
        D.info("Accept language set to \(lang)")
    }
    
    // MARK: - Private Helper Methods
    /// Defines if the `WMTOperations` is created from provided WPNConfig or from default values
    private func createOperations() -> WMTOperations {
        D.debug("Creating OperationsService in WultraMobileToken")
        return WMTOperations(
            networking: WPNNetworkingService(
                powerAuth: powerAuth,
                config: WPNConfig(baseUrl: baseURL),
                serviceName: "WMTOperations",
                acceptLanguage: acceptLanguage
            )
        )
    }
    
    /// Defines if the `WMTInbox` is created from provided WPNConfig or from default values
    private func createInbox() -> WMTInbox {
        D.debug("Creating InboxService in WultraMobileToken")
        return WMTInbox(
            networking: WPNNetworkingService(
                powerAuth: powerAuth,
                config: WPNConfig(baseUrl: baseURL),
                serviceName: "WMTInbox",
                acceptLanguage: acceptLanguage
            )
        )
    }
    
    /// Defines if the `WMTPush` is created from provided WPNConfig or from default values
    private func createPush() -> WMTPush {
        D.debug("Creating PushService in WultraMobileToken")
        return WMTPush(
            networking: WPNNetworkingService(
                powerAuth: powerAuth,
                config: WPNConfig(baseUrl: baseURL),
                serviceName: "WMTPush",
                acceptLanguage: acceptLanguage
            )
        )
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
    
    /// Helper function to resolve and validate URLs
    private static func resolveURL(from urlString: String) throws -> URL {
        guard let url = URL(string: urlString) else {
            throw InitError.invalidBaseURL(url: urlString)
        }
        return url
    }
}
