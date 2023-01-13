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

/// Structure contains information about message in inbox.
public struct WMTInboxMessage: Codable {
    /// Message's identifier.
    public let id: String
    /// Message's subject.
    public let subject: String
    /// Message's summary. It typically contains a reduced
    /// information from message's body, with no additional formatting.
    public let summary: String
    /// Message body's content type.
    public let type: WMTInboxContentType
    /// If `true`, then user already read the message.
    public let read: Bool
    /// Date and time when the message was created.
    public let timestampCreated: Date
}
