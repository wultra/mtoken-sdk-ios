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
import WultraPowerAuthNetworking

/// Config data contains essential OIDC configuration values for authentication.
public struct WMTOidcConfig: Codable {
    
    /// Provider's identifier.
    public let providerId: String
    
    /// Identification of the OAuth 2.0 client, to form the URL for authorize request
    public let clientId: String
    
    /// OAuth 2.0 scopes, to form the URL for authorize request
    public let scopes: String
    
    /// OAuth 2.0 authorize URI, to form the URL for authorize request
    public let authorizeUri: String
    
    /// OAuth 2.0 redirect URI, the endpoint to which the OAuth 2.0 server can send responses.
    public let redirectUri: String
    
    /// If PKCE(Proof Key for Code Exchange) extension should be used
    public let pkceEnabled: Bool
}
