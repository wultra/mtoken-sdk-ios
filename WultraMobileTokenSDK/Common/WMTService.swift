//
// Copyright 2022 Wultra s.r.o.
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

protocol WMTService {
    var powerAuth: PowerAuthSDK { get }
}

extension WMTService {
    
    /// Checks if the PowerAuth object contains a valid activation.
    ///
    /// - Parameter completion: Completion
    /// - Returns: True if the activation is valid
    func validateActivation<T>(_ completion: @escaping (Result<T, WMTError>) -> Void) -> Bool {
        guard powerAuth.hasValidActivation() else {
            DispatchQueue.main.async {
                completion(.failure(WMTError(reason: .missingActivation)))
            }
            return false
        }
        return true
    }
    
    func processResult<TResult: WPNResponse<TData>, TData>(response: TResult?, error: WPNError?, completion: @escaping (Result<TData, WMTError>) -> Void) {
        assert(Thread.isMainThread)
        if let result = response?.responseObject {
            completion(.success(result))
        } else {
            completion(.failure(error ?? WMTError(reason: .unknown)))
        }
    }
    
    func processResult<TResult: WPNResponseArray<TData>, TData>(response: TResult?, error: WPNError?, completion: @escaping (Result<[TData], WMTError>) -> Void) {
        assert(Thread.isMainThread)
        if let result = response?.responseObject {
            completion(.success(result))
        } else {
            completion(.failure(error ?? WMTError(reason: .unknown)))
        }
    }
    
    func processResult(response: WPNResponseBase?, error: WPNError?, completion: @escaping (Result<Void, WMTError>) -> Void) {
        assert(Thread.isMainThread)
        if let error = error {
            completion(.failure(error))
        } else {
            completion(.success(()))
        }
    }
}
