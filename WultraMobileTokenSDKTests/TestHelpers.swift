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
@testable import WultraMobileTokenSDK

// MARK: - Base integration test class

/// Base class for integration tests that need an activated `PowerAuthSDK`
/// instance backed by a running server. Subclasses inherit `proxy`, `pa`,
/// `wmt`, and `ops`; the activation is torn down automatically in `deinit`.
///
/// See `WultraMobileTokenSDKTests/Configs/Readme.md` for setup instructions.
class BaseIntegrationTests {
    
    let proxy: IntegrationProxy
    let wmt: WultraMobileToken
    var pa: PowerAuthSDK { proxy.powerAuth! }
    var ops: WMTOperations { wmt.operations }
    
    let pin: String
    
    /// - Parameters:
    ///   - pin: PIN used for activation and authentication.
    ///   - algorithm: PowerAuth algorithm to initialise with.
    init(pin: String = "1234", algorithm: PowerAuthAlgorithm = .DEFAULT) async throws {
        self.pin = pin
        WMTLogger.verboseLevel = .debug
        let loaded = try #require(TestConfiguration.load(), "Missing config.json — see WultraMobileTokenSDKTests/Configs/Readme.md")
        proxy = IntegrationProxy(config: loaded.config, pin: pin)
        try await proxy.initializePowerauth(algorithm: algorithm)
        try await proxy.prepareActivation()
        wmt = try proxy.powerAuth!.createWultraMobileToken()
    }
    
    deinit {
        let auth = PowerAuthAuthentication.possessionWithPassword(password: pin)
        let semaphore = DispatchSemaphore(value: 0)
        if let pa = proxy.powerAuth {
            pa.removeActivation(with: auth) { _ in
                semaphore.signal()
            }
            semaphore.wait()
        }
    }
}

// MARK: - Async test signaling

/// Async/await-friendly one-shot signal usable in Swift Testing tests.
actor AsyncTestSignal {
    private var fulfilled = false
    private var continuations = [CheckedContinuation<Void, Never>]()

    func fulfill() {
        guard !fulfilled else { return }
        fulfilled = true
        continuations.forEach { $0.resume() }
        continuations.removeAll()
    }

    func wait() async {
        if fulfilled { return }
        await withCheckedContinuation { continuation in
            continuations.append(continuation)
        }
    }
}

struct AsyncTestTimeout: Error, CustomStringConvertible {
    let description: String
}

func wait(for signal: AsyncTestSignal, timeout: TimeInterval) async throws {
    try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask {
            await signal.wait()
        }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            throw AsyncTestTimeout(description: "Timed out after \(timeout) seconds.")
        }
        try await group.next()
        group.cancelAll()
    }
}

// MARK: - Config loading

/// Loads integration test configuration from `config.json` bundled with the
/// test target. See `Configs/Readme.md` for setup instructions.
class TestConfiguration {

    /// Full configuration as loaded from `config.json`.
    struct LoadedConfig: Decodable {
        let cloudServerUrl: String
        let cloudServerLogin: String
        let cloudServerPassword: String
        let cloudApplicationId: String
        let enrollmentServerUrl: String
        let oidcProviderId: String?
        let oidcProviderIdPkce: String?

        /// Subset of fields suitable for `IntegrationProxy(config:)`.
        var config: Config {
            Config(
                cloudServerUrl: cloudServerUrl,
                cloudServerLogin: cloudServerLogin,
                cloudServerPassword: cloudServerPassword,
                cloudApplicationId: cloudApplicationId,
                enrollmentServerUrl: enrollmentServerUrl,
                oidcProviderId: oidcProviderId,
                oidcProviderIdPkce: oidcProviderIdPkce
            )
        }
    }

    /// Loads the integration `LoadedConfig` from the test bundle.
    /// Returns `nil` if no `config.json` is present.
    static func load() -> LoadedConfig? {
        let bundle = Bundle(for: TestConfiguration.self)
        let url = bundle.url(forResource: "config", withExtension: "json", subdirectory: "Configs")
            ?? bundle.url(forResource: "config", withExtension: "json")
        guard let url, let data = try? Data(contentsOf: url) else {
            print("[TestConfiguration] Config not found in test bundle")
            return nil
        }
        print("[TestConfiguration] Config loaded from \(url.lastPathComponent)")
        return try? JSONDecoder().decode(LoadedConfig.self, from: data)
    }
}
