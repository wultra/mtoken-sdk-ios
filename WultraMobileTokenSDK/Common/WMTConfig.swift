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

/// Configuration class used for configuring WultraMobileTokenSDK services.
public class WMTConfig {
    
    /// Base URL for service requests.
    public let baseUrl: URL
    
    /// SSL validation strategy for the request.
    public let sslValidation: WMTSSLValidationStrategy
    
    /// Accept language for the outgoing requests headers
    public var acceptLanguage: String
    
    public init(baseUrl: URL, sslValidation: WMTSSLValidationStrategy, acceptLanguage: String) {
        self.baseUrl = baseUrl
        self.sslValidation = sslValidation
        self.acceptLanguage = acceptLanguage
    }
    
    internal func buildURL(_ endpoint: String) -> URL {
        
        var relativePath = endpoint
        var url = baseUrl
        
        // if relative path starts with "/", lets remove it to create valid URL
        if relativePath.hasPrefix("/") {
            relativePath.removeFirst()
        }
        
        url.appendPathComponent(relativePath)
        
        return url
    }
}
