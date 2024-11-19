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

internal extension Data {
    
    static let toHexTable: [Character] = [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F" ]
    
    func toHex() -> String {
        var result = ""
        result.reserveCapacity(count * 2)
        for byte in self {
            let byteAsUInt = Int(byte)
            result.append(Self.toHexTable[byteAsUInt >> 4])
            result.append(Self.toHexTable[byteAsUInt & 15])
        }
        return result
    }
}
