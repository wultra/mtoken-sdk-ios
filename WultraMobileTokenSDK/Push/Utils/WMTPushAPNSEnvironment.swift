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

/// APNS push environment.
///
/// Production environment (server) must be used for production signed apps. (For example TestFlight or AppStore distrubution).
/// Development environment (server) must be used for developer-signed apps. (For example debug builds or ad-hoc development distrubition).
public enum WMTPushAPNSEnvironment {
    /// Automatically detect how is the app signed and set the environment properly.
    ///
    /// When automatic detection fails, environment is not sent at all and server configuration is used.
    case automatic
    /// Production APNS environment for production-signed app (TestFlight and AppStore distribution).
    case production
    /// Development signed app.
    case development
}
