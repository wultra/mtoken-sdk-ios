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
}
