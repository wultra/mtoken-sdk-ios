//
// Copyright 2023 Wultra s.r.o.
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

// JSONValue is helper enum to decode generic response
public enum WMTJSONValue: Codable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case object([String: WMTJSONValue])
    case array([WMTJSONValue])
    case null
    
    public subscript(key: String) -> WMTJSONValue? {
        if case .object(let object) = self {
            return object[key]
        }
        return nil
    }
    
    public init(from decoder: Decoder) throws {
        if let c = try? decoder.singleValueContainer(),
           let string = try? c.decode(String.self) {
            self = .string(string)
        } else if let c = try? decoder.container(keyedBy: AnyCodingKey.self) {
            var object = [String: WMTJSONValue]()
            for key in c.allKeys {
                object[key.stringValue] = try c.decode(WMTJSONValue.self, forKey: key)
            }
            self = .object(object)
        } else if var c = try? decoder.unkeyedContainer() {
            var array = [WMTJSONValue]()
            while !c.isAtEnd {
                array.append(try c.decode(WMTJSONValue.self))
            }
            self = .array(array)
        } else if let c = try? decoder.singleValueContainer() {
            if c.decodeNil() {
                self = .null
            } else if let bool = try? c.decode(Bool.self) {
                self = .bool(bool)
            } else if let int = try? c.decode(Int.self) {
                self = .int(int)
            } else if let double = try? c.decode(Double.self) {
                self = .double(double)
            } else if let string = try? c.decode(String.self) {
                self = .string(string)
            } else {
                let data = try JSONSerialization.data(withJSONObject: decoder)
                if let string = String(data: data, encoding: .utf8) {
                    self = .object(["error": .string("Unknown JSON pattern"), "json": .string(string)])
                } else {
                    self = .object(["error": .string("Unknown JSON pattern"), "json": .null])
                }
            }
        } else {
            let data = try JSONSerialization.data(withJSONObject: decoder)
            if let string = String(data: data, encoding: .utf8) {
                self = .object(["error": .string("Unknown JSON pattern"), "json": .string(string)])
            } else {
                self = .object(["error": .string("Unknown JSON pattern"), "json": .null])
            }
        }
    }
    public init(jsonData: Data) throws {
        let decoder = JSONDecoder()
        self = try decoder.decode(WMTJSONValue.self, from: jsonData)
    }
}

/// Helper struct for key: value decoding
struct AnyCodingKey: CodingKey {
    
    /// property to hold the key's name as a string
    var stringValue: String
    
    /// optional property to hold the key's index if it's an array index.
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}
