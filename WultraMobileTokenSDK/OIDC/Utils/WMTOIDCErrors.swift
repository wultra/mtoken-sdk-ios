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

/// Extension to `WMTErrorReason` to define specific error reasons used in the OIDC (OpenID Connect) process.
public extension WMTErrorReason {
    
    /// Error reason for failure when generating random bytes for cryptographic purposes.
    static let randomBytesFailed = WMTErrorReason(rawValue: "randomBytesFailed")
    
    /// Error reason for failure during the generation of the PKCE code challenge.
    static let codeChallengeGenerationFailed = WMTErrorReason(rawValue: "codeChallengeGenerationFailed")
    
    /// Error reason indicating that the callback scheme could not be found or determined.
    static let schemeNotFound = WMTErrorReason(rawValue: "schemeNotFound")
    
    /// Error reason for an invalid deeplink, which could not be parsed or handled.
    static let invalidDeeplink = WMTErrorReason(rawValue: "invalidDeeplink")
    
    /// Error reason for failure during the creation of the authorization URL required for OIDC.
    static let authorizationUrlCreationFailed = WMTErrorReason(rawValue: "authorizationUrlCreationFailed")
    
    /// Error reason for failure when generating random bytes for cryptographic purposes.
    static let activationFailed = WMTErrorReason(rawValue: "activationFailed")
}
