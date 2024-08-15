//
// Copyright 2024 Wultra s.r.o.
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

/// Texts for the result of the operation.
///
/// This includes messages for different outcomes of the operation such as success, rejection, and failure.
public class WMTResultTexts: Codable {
    
    /// Optional message to be displayed when the approval of the operation is successful.
    public let success: String?
    
    /// Optional message to be displayed when the operation approval or rejection fails.
    public let failure: String?
    
    /// Optional message to be displayed when the operation is rejected.
    public let reject: String?
    
    // MARK: - INTERNALS
    
    private enum Keys: CodingKey {
        case success, failure, reject
    }
    
    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        
        do {
            success = try c.decodeIfPresent(String.self, forKey: .success)
        } catch {
            D.error("Failed to decode \(Keys.success) - \(error), setting to null")
            success = nil
        }
        
        do {
            failure = try c.decodeIfPresent(String.self, forKey: .failure)
        } catch {
            D.error("Failed to decode \(Keys.failure) - \(error), setting to null")
            failure = nil
        }
        
        do {
            reject = try c.decodeIfPresent(String.self, forKey: .reject)
        } catch {
            D.error("Failed to decode \(Keys.reject) - \(error), setting to null")
            reject = nil
        }
    }
    
    public init(success: String?, failure: String?, reject: String?) {
        self.success = success
        self.failure = failure
        self.reject = reject
    }
}
