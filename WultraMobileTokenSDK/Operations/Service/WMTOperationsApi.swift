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

/// Internal protocol abstracting the authorize network call.
/// `WPNNetworkingService` conforms via extension; tests provide a mock.
protocol WMTOperationsApi: AnyObject {
    @discardableResult
    func authorize(data: WMTAuthorizationData, authentication: PowerAuthAuthentication, completion: @escaping (Result<Void, WMTError>) -> Void) -> Operation?
}

/// Production conformance — delegates to WPNNetworkingService.post(...)
extension WPNNetworkingService: WMTOperationsApi {
    func authorize(data: WMTAuthorizationData, authentication: PowerAuthAuthentication, completion: @escaping (Result<Void, WMTError>) -> Void) -> Operation? {
        return post(data: .init(data), authenticatedWith: authentication, to: WMTOperationEndpoints.Authorize.endpoint) { _, error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
