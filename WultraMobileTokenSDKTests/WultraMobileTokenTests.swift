//
// Copyright 2026 Wultra s.r.o.
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
import Testing
import WultraPowerAuthNetworking
@testable import WultraMobileTokenSDK

/// `WPNConfig`'s own defaulting/ordering behavior for `requestInterceptors` is covered in
/// `networking-apple`'s `WPNConfigTests`. These tests only cover the wiring added on top of it:
/// that `WultraMobileToken.init`/`createWultraMobileToken` actually forward the parameter to
/// every lazily created service. No activation is needed - see
/// `WultraMobileTokenSDKTests/Configs/Readme.md` for the required config.json setup.
@Suite(.serialized)
final class WultraMobileTokenTests {

    private let proxy: IntegrationProxy

    init() async throws {
        let loaded = try #require(TestConfiguration.load(), "Missing config.json — see WultraMobileTokenSDKTests/Configs/Readme.md")
        proxy = IntegrationProxy(config: loaded.config)
        try await proxy.initializePowerauth()
    }

    @Test("requestInterceptors are forwarded to every service's networking config")
    func requestInterceptorsAreForwardedToAllServices() throws {
        let first = NamedInterceptor("first")
        let second = NamedInterceptor("second")

        let wmt = try WultraMobileToken(powerAuth: proxy.powerAuth!, requestInterceptors: [first, second])

        for interceptors in [
            wmt.operations.networking.config.requestInterceptors,
            wmt.push.networking.config.requestInterceptors,
            wmt.inbox.networking.config.requestInterceptors,
            wmt.oidc.networking.config.requestInterceptors
        ] {
            let names = interceptors.compactMap { ($0 as? NamedInterceptor)?.name }
            #expect(names == ["first", "second"])
        }
    }

    @Test("PowerAuthSDK.createWultraMobileToken forwards requestInterceptors")
    func createWultraMobileTokenForwardsRequestInterceptors() throws {
        let interceptor = NamedInterceptor("only")

        let wmt = try proxy.powerAuth!.createWultraMobileToken(requestInterceptors: [interceptor])

        let names = wmt.operations.networking.config.requestInterceptors.compactMap { ($0 as? NamedInterceptor)?.name }
        #expect(names == ["only"])
    }

    @Test("Interceptor sets the X-Correlation-ID header on the request")
    func interceptorSetsCorrelationIdHeader() {
        let interceptor = NamedInterceptor("correlation")
        let request = NSMutableURLRequest(url: URL(string: "https://example.com")!)

        interceptor.processRequest(request)

        let correlationId = request.value(forHTTPHeaderField: "X-Correlation-ID")
        #expect(correlationId != nil)
        #expect(UUID(uuidString: correlationId ?? "") != nil)
    }

    // MARK: - Helpers

    private final class NamedInterceptor: WPNInterceptor {
        let name: String
        init(_ name: String) { self.name = name }
        func processRequest(_ request: NSMutableURLRequest) {
            request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Correlation-ID")
        }
    }
}
