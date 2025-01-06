/*
 * Copyright (c) 2024, Wultra s.r.o. (www.wultra.com).
 *
 * All rights reserved. This source code can be used only for purposes specified 
 * by the given license contract signed by the rightful deputy of Wultra s.r.o. 
 * This source code can be used only by the owner of the license.
 * 
 * Any disputes arising in respect of this agreement (license) shall be brought
 * before the Municipal Court of Prague.
 *
 */ 

import Foundation
import PowerAuth2
import WultraPowerAuthNetworking

public extension PowerAuthSDK {
    func createWultraMobileToken(
        acceptLanguage: String = "en",
        userAgent: WPNUserAgent = .libraryDefault
    ) throws -> WultraMobileToken {
        try WultraMobileToken(powerAuth: self, acceptLanguage: acceptLanguage, userAgent: userAgent)
    }
    
    func createWultraMobileToken(
        operationsConfig: WPNConfig,
        pushConfig: WPNConfig? = nil,
        inboxConfig: WPNConfig? = nil,
        acceptLanguage: String = "en"
    ) -> WultraMobileToken {
        WultraMobileToken(
            powerAuth: self,
            operationsConfig: operationsConfig,
            pushConfig: pushConfig,
            inboxConfig: inboxConfig,
            acceptLanguage: acceptLanguage
        )
    }
}

/**
 * `WultraMobileToken` class exposes APIs that enable fetching, authorizing, or rejecting basic
 * operations created in the PowerAuth stack.
 */
public class WultraMobileToken {
    
    /// Operations manager. Use for fetching pending lists, approving operations, etc.
    public lazy var operations: WMTOperations = createOperations()
    
    /// Push manager for registering the device to receive PowerAuth push notifications for a given PowerAuth activation.
    public lazy var push: WMTPush = createPush()
    
    /// Inbox manager - receives messages to communicate with the user.
    public lazy var inbox: WMTInbox = createInbox()
    
    // MARK: - Private Properties
    private let powerAuth: PowerAuthSDK
    private let userAgent: WPNUserAgent?
    
    private var baseURL: URL
    private var operationsConfig: WPNConfig?
    private var pushConfig: WPNConfig?
    private var inboxConfig: WPNConfig?
    private var acceptLanguage: String
    
    // MARK: - Errors
    public enum InitError: LocalizedError {
        /// Provided URL is invalid (see `url` associated value)
        case invalidBaseURL(url: String)
        
        public var errorDescription: String? {
            switch self {
            case .invalidBaseURL(let url): return "invalidBaseURL: Provided URL is invalid: \(url)"
            }
        }
    }
    
    // MARK: - Initializers
    /**
     Initializes a new instance of `WultraMobileToken`.
     
     - Parameters:
       - powerAuth: `PowerAuth` instance. Needs to be activated when calling any method of this class; otherwise, an error will be thrown.
       - acceptLanguage: The language code to set for the `Accept-Language` header.
       - userAgent: User agent that will be used in a HTTP header.
     */
    public init(
        powerAuth: PowerAuthSDK,
        acceptLanguage: String = "en",
        userAgent: WPNUserAgent = .libraryDefault
    ) throws {
        self.powerAuth = powerAuth
        self.acceptLanguage = acceptLanguage
        self.userAgent = userAgent
        self.baseURL = try Self.resolveURL(from: powerAuth.configuration.baseEndpointUrl)
        self.operationsConfig = nil
        self.pushConfig = nil
        self.inboxConfig = nil

        D.debug("Default Wultra Mobile Token object created with:")
        D.debug(" - baseURL: \(powerAuth.configuration.baseEndpointUrl)")
    }
    
    /**
     Initializes a new instance of `WultraMobileToken`.
     
     - Parameters:
       - powerAuth: `PowerAuth` instance. Needs to be activated when calling any method of this class; otherwise, an error will be thrown.
       - operationsConfig: `WultraPowerAuthNetworking Config` or also WPNConfig consist of:
                    - `baseURL` - Base URL for service requests.
                    - `sslValidation` - SSL validation strategy for the request.
                    - `timeoutIntervalForRequest` - The timeout interval to use when waiting for backend data.
                    - `userAgent` - Property that specifies the content of the User-Agent request header.
                    - for additional info visit networking apple repository at: https://github.com/wultra/networking-apple
     
       - pushConfig: Similarly as operationsConfig, pushConfig consists of networking configuration. If nil, same config as for operations is used.
       - inboxConfig: Similarly as operationsConfig, inboxConfig consists of networking configuration. If nil, same config as for operations is used.
       - acceptLanguage: The language code to set for the `Accept-Language` header. The default value is `"en"`
     */
    public init(
        powerAuth: PowerAuthSDK,
        operationsConfig: WPNConfig,
        pushConfig: WPNConfig? = nil,
        inboxConfig: WPNConfig? = nil,
        acceptLanguage: String = "en"
    ) {
        self.powerAuth = powerAuth
        self.acceptLanguage = acceptLanguage
        self.userAgent = operationsConfig.userAgent
        self.baseURL = operationsConfig.baseUrl
        self.operationsConfig = operationsConfig
        self.pushConfig = pushConfig ?? operationsConfig
        self.inboxConfig = inboxConfig ?? operationsConfig
        
        D.debug("Wultra Mobile Token object created with:")
        D.debug(" - operationsConfig: \(operationsConfig)")
        D.debug(" - pushConfig: \(pushConfig ?? operationsConfig)")
        D.debug(" - inboxConfig: \(inboxConfig ?? operationsConfig)")
        D.debug(" - lang: \(acceptLanguage)")
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
        operations.acceptLanguage = lang
        push.acceptLanguage = lang
        inbox.acceptLanguage = lang
        D.info("Accept language set to \(lang)")
    }
    
    // MARK: - Private Helper Methods
    /// Defines if the `WMTOperations` is created from provided WPNConfig or from default values
    private func createOperations() -> WMTOperations {
        D.debug("creatingOperations = \(operationsConfig ?? WPNConfig(baseUrl: baseURL))")
        return WMTOperations(
            networking: WPNNetworkingService(
                powerAuth: powerAuth,
                config: operationsConfig ?? WPNConfig(baseUrl: baseURL),
                serviceName: "WMTOperations",
                acceptLanguage: acceptLanguage
            )
        )
    }
    
    /// Defines if the `WMTInbox` is created from provided WPNConfig or from default values
    private func createInbox() -> WMTInbox {
        D.debug("creatingInbox = \(inboxConfig ?? WPNConfig(baseUrl: baseURL))")
        return WMTInbox(
            networking: WPNNetworkingService(
                powerAuth: powerAuth,
                config: inboxConfig ?? WPNConfig(baseUrl: baseURL),
                serviceName: "WMTInbox",
                acceptLanguage: acceptLanguage
            )
        )
    }
    
    /// Defines if the `WMTPush` is created from provided WPNConfig or from default values
    private func createPush() -> WMTPush {
        D.debug("creatingPush = \(pushConfig ?? WPNConfig(baseUrl: baseURL))")
        return WMTPush(
            networking: WPNNetworkingService(
                powerAuth: powerAuth,
                config: pushConfig ?? WPNConfig(baseUrl: baseURL),
                serviceName: "WMTPush",
                acceptLanguage: acceptLanguage
            )
        )
    }
    
    // Helper function to resolve and validate URLs
    private static func resolveURL(from urlString: String) throws -> URL {
        guard let url = URL(string: urlString) else {
            throw InitError.invalidBaseURL(url: urlString)
        }
        return url
    }
}
