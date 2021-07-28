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
import PowerAuth2

/// If you want to use SSL pinning for the requests, implement this protocol
/// and use it inside `WMTSSLValidationStrategy.sslPinning` case.
public protocol WMTPinningProvider {
    func validate(challenge: URLAuthenticationChallenge) -> Bool
}

/// Validation strategy decides how HTTP(S) requests should be handled.
public enum WMTSSLValidationStrategy {
    /// Will use default URLSession handling
    case `default`
    /// Will trust https connections with invalid certificates
    case noValidation
    /// Will validate server certificate against SSL pinning provider
    case sslPinning(_ provider: WMTPinningProvider)
    
    internal func validate(challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        switch self {
        case .noValidation:
            if let st = challenge.protectionSpace.serverTrust {
                completionHandler(.useCredential, URLCredential(trust: st))
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        case .sslPinning(let provider):
            if provider.validate(challenge: challenge) {
                completionHandler(.performDefaultHandling, nil)
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        case .default:
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    /// Returns PowerAuth2 compatible object for SSL validation
    internal func createPA2ValidationStrategy() -> PowerAuthClientSslValidationStrategy {
        return PA2ValidationStrategy(strategy: self)
    }
}

// PowerAuth compatible wrapper for ssl strategy
fileprivate class PA2ValidationStrategy: NSObject, PowerAuthClientSslValidationStrategy {
    
    private let strategy: WMTSSLValidationStrategy
    
    init(strategy: WMTSSLValidationStrategy) {
        self.strategy = strategy
    }
    
    func validateSsl(for session: URLSession, challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        strategy.validate(challenge: challenge, completionHandler: completionHandler)
    }
}
