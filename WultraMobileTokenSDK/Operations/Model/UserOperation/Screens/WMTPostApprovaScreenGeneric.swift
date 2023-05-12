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

public class WMTPostApprovalScreenGeneric: WMTPostApprovalScreen {
    
    /// Heading of the post-approval screen
    public let heading: String
    
    /// Message to the user
    public let message: String
    
    /// Payload with data about action after the operation
    public let payload: GenericPostApprovalScreenPayload

    // MARK: Internals
    
    private enum Keys: String, CodingKey {
        case heading, message, payload
    }

    public required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        heading = try c.decode(String.self, forKey: .heading)
        message = try c.decode(String.self, forKey: .message)
        payload = try c.decode(GenericPostApprovalScreenPayload.self, forKey: .payload)
        try super.init(from: decoder)
    }
    
    public init(heading: String, message: String, payload: GenericPostApprovalScreenPayload) {
        self.heading = heading
        self.message = message
        self.payload = payload
        super.init(type: .generic)
    }
}

///Payload of the generic post-approval screen may contain any object.
///
///So it implements custome JSONValue for decoding generic response
public class GenericPostApprovalScreenPayload: PostApprovalScreenPayload {
    
    /// Generic Custom message may contain any object, kept to be String
    public let customMessage: JSONValue
    
    // MARK: Internals
    
    private enum Keys: String, CodingKey {
        case customMessage
    }
    
    public init(customMessage: JSONValue) throws {
        self.customMessage = customMessage
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        customMessage = try c.decode(JSONValue.self, forKey: .customMessage)
        super.init()
    }
    
    public enum JSONValue: Codable, Equatable {
        case string(String)
        case int(Int)
        case double(Double)
        case bool(Bool)
        case object([String: JSONValue])
        case array([JSONValue])
        case null
        
        public subscript(key: String) -> JSONValue? {
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
                var object = [String: JSONValue]()
                for key in c.allKeys {
                    object[key.stringValue] = try c.decode(JSONValue.self, forKey: key)
                }
                self = .object(object)
            } else if var c = try? decoder.unkeyedContainer() {
                var array = [JSONValue]()
                while !c.isAtEnd {
                    array.append(try c.decode(JSONValue.self))
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
}
