//
// Copyright 2020 Wultra s.r.o.
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
import WultraMobileTokenSDK
import WultraPowerAuthNetworking

class IntegrationProxy {
    
    private(set) var powerAuth: PowerAuthSDK?
    private(set) var wmt: WultraMobileToken?
    private(set) var ops: WMTOperations?
    private(set) var inbox: WMTInbox?
    private(set) var push: WMTPush?
    
    private var config: IntegrationConfig!
    private let activationName = UUID().uuidString
    private var registrationId = "" // will be filled when activation is created
    
    typealias Callback = (_ error: String?) -> Void
    
    func prepareActivation(pin: String, configFileName: String = "config") async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            prepareActivation(pin: pin, configFileName: configFileName) { error in
                if let error {
                    continuation.resume(throwing: IntegrationProxyError(message: error))
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func prepareActivation(pin: String, configFileName: String = "config", callback: @escaping Callback) {
        WPNLogger.verboseLevel = .debug
        
        guard let configPath = Bundle.init(for: IntegrationProxy.self).path(forResource: configFileName, ofType: "json", inDirectory: "Configs") else {
            callback("Config file \(configFileName).json is not present.")
            return
        }
        
        do {
            let configContent = try String(contentsOfFile: configPath)
            config = try JSONDecoder().decode(IntegrationConfig.self, from: configContent.data(using: .utf8)!)
        } catch _ {
            callback("Config file \(configFileName).json cannot be parsed.")
            return
        }
        
        let pa = preparePAInstance()
        enrollPAInstance(pa: pa, pin: pin) { error in
            if let error = error {
                callback(error)
            } else {
                self.powerAuth = pa
            
                // use in case you have only one enrollment server baseURL
                //self.wmt = try! pa.createWultraMobileToken()
                
                // use if your operations and inbox urls are diffferent - set in config file `WultraMobileTokenSDKTests/Configs/Readme.md`
                let wpnOperationsConf = WPNConfig(baseUrl: URL(string: self.config.operationsServerUrl)!, sslValidation: .noValidation)
                let wpnInboxConf = WPNConfig(baseUrl: URL(string: self.config.inboxServerUrl)!, sslValidation: .noValidation)
                let wpnPushConf = WPNConfig(baseUrl: URL(string: self.config.pushServerUrl)!, sslValidation: .noValidation)
                self.ops = WMTOperations(networking: WPNNetworkingService(powerAuth: pa, config: wpnOperationsConf, serviceName: "WMTOperations"))
                self.inbox = WMTInbox(networking: WPNNetworkingService(powerAuth: pa, config: wpnInboxConf, serviceName: "WMTInbox"))
                self.push = WMTPush(networking: WPNNetworkingService(powerAuth: pa, config: wpnPushConf, serviceName: "WMTPush"))
                callback(nil)
            }
        }
    }
    
    func prepareForOIDC() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            prepareForOIDC { error in
                if let error {
                    continuation.resume(throwing: IntegrationProxyError(message: error))
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func prepareForOIDC(callback: @escaping Callback) {
        WPNLogger.verboseLevel = .debug
        guard let configPath = Bundle.init(for: IntegrationProxy.self).path(forResource: "config", ofType: "json", inDirectory: "Configs") else {
            callback("Config file config.json is not present.")
            return
        }
        
        do {
            let configContent = try String(contentsOfFile: configPath)
            config = try JSONDecoder().decode(IntegrationConfig.self, from: configContent.data(using: .utf8)!)
        } catch {
            callback("Config file config.json cannot be parsed.")
            return
        }
        
        powerAuth = preparePAInstance()
        do {
            wmt = try powerAuth?.createWultraMobileToken()
        } catch {
            callback("Failed to create WultraMobileToken from PA baseUrl.")
        }
        callback(nil)
    }
    
    enum Factors {
        // TODO: temp unsupported
        //case OF_1FA
        case F_2FA
    }
    
    func createOperation(_ factors: Factors = .F_2FA) async throws -> OperationObject {
        try await asyncObject { completion in
            createOperation(factors, completion: completion)
        }
    }
    
    func createOperation(_ factors: Factors = .F_2FA, completion: @escaping (OperationObject?) -> Void) {
        DispatchQueue.global().async {
            let opBody: String
            switch factors {
            case .F_2FA:
                opBody = """
                {
                  "userId": "\(self.activationName)",
                  "template": "login",
                   "parameters": {
                     "party.id": "666",
                     "party.name": "Datová schránka",
                         "session.id": "123",
                         "session.ip-address": "192.168.0.1"
                   }
                }
                """
            }
            
            completion(self.makeRequest(url: URL(string: "\(self.config.cloudServerUrl)/v2/operations")!, body: opBody))
        }
    }
    
    func cancelOperation(operationId: String, reason: String) async throws -> CancelObject {
        try await asyncObject { completion in
            cancelOperation(operationId: operationId, reason: reason, completion: completion)
        }
    }
    
    func cancelOperation(operationId: String, reason: String, completion: @escaping (CancelObject?) -> Void) {
        DispatchQueue.global().async {
            completion(self.makeRequest(url: URL(string: "\(self.config.cloudServerUrl)/v2/operations/\(operationId)?statusReason=\(reason)")!, body: "", httpMethod: "DELETE"))
        }
    }
    
    func createNonPersonalisedPACOperation(_ factors: Factors = .F_2FA) async throws -> OperationObject {
        try await asyncObject { completion in
            createNonPersonalisedPACOperation(factors, completion: completion)
        }
    }
    
    func createNonPersonalisedPACOperation(_ factors: Factors = .F_2FA, completion: @escaping (OperationObject?) -> Void) {
        DispatchQueue.global().async {
            let opBody: String
            switch factors {
            case .F_2FA:
                opBody = """
                {
                  "template": "login_preApproval",
                  "proximityCheckEnabled": true,
                   "parameters": {
                     "party.id": "666",
                     "party.name": "Datová schránka",
                         "session.id": "123",
                         "session.ip-address": "192.168.0.1"
                   }
                }
                """
            }
            
            completion(self.makeRequest(url: URL(string: "\(self.config.cloudServerUrl)/v2/operations")!, body: opBody))
        }
    }
    
    func getOperation(operationId: String) async throws -> OperationObject {
        try await asyncObject { completion in
            getOperation(operationId: operationId, completion: completion)
        }
    }
    
    func getOperation(operationId: String, completion: @escaping (OperationObject?) -> Void) {
        DispatchQueue.global().async {
            completion(self.makeRequest(url: URL(string: "\(self.config.cloudServerUrl)/v2/operations/\(operationId)")!, body: "", httpMethod: "GET"))
        }
    }
    
    func getQROperation(operationId: String) async throws -> QROperationData {
        try await asyncObject { completion in
            getQROperation(operationId: operationId, completion: completion)
        }
    }
    
    func getQROperation(operationId: String, completion: @escaping (QROperationData?) -> Void) {
        DispatchQueue.global().async {
            completion(self.makeRequest(url: URL(string: "\(self.config.cloudServerUrl)/v2/operations/\(operationId)/offline/qr?registrationId=\(self.registrationId)")!, body: "", httpMethod: "GET"))
        }
    }
    
    func verifyQROperation(operationId: String, operationData: QROperationData, otp: String) async throws -> QROperationVerify {
        try await asyncObject { completion in
            verifyQROperation(operationId: operationId, operationData: operationData, otp: otp, completion: completion)
        }
    }
    
    func verifyQROperation(operationId: String, operationData: QROperationData, otp: String, completion: @escaping (QROperationVerify?) -> Void) {
        DispatchQueue.global().async {
            let body = """
                {
                  "otp": "\(otp)",
                  "nonce": "\(operationData.nonce)",
                  "registrationId": "\(self.registrationId)"
                }
            """
            completion(self.makeRequest(url: URL(string: "\(self.config.cloudServerUrl)/v2/operations/\(operationId)/offline/otp")!, body: body))
        }
    }
    
    func createInboxMessages(count: Int, defaultType: String = "text", createFunc: ((Int) -> InboxMessage)? = nil) async -> [InboxMessageDetail] {
        await withCheckedContinuation { continuation in
            createInboxMessages(count: count, defaultType: defaultType, createFunc: createFunc) { messages in
                continuation.resume(returning: messages)
            }
        }
    }
    
    func createInboxMessages(count: Int, defaultType: String = "text", createFunc: ((Int) -> InboxMessage)? = nil, completion: @escaping ([InboxMessageDetail]) -> Void) {
        DispatchQueue.global().async {
            var result = [InboxMessageDetail]()
            for index in 1...count {
                let message = createFunc?(count) ??
                    InboxMessage(
                        subject: "Message #\(index)",
                        summary: "This is body for message \(index).",
                        body: "This is body for message \(index).",
                        type: defaultType
                    )
                let body = """
                {
                    "userId":"\(self.activationName)",
                    "subject":"\(message.subject)",
                    "summary":"\(message.summary)",
                    "body":"\(message.body)",
                    "type":"\(message.type)",
                    "silent":true
                }
                """
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .millisecondsSince1970
                let url = URL(string: "\(self.config.cloudServerUrl)/v2/inbox/messages")!
                guard let createdMessage: InboxMessageDetail = self.makeRequest(url: url, body: body, decoder: decoder) else {
                    print("ERROR: Failed to create message #\(index)")
                    continue
                }
                result.append(createdMessage)
            }
            completion(result)
        }
    }
    
    private func asyncObject<T>(_ work: (@escaping (T?) -> Void) -> Void) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            work { object in
                if let object {
                    continuation.resume(returning: object)
                } else {
                    continuation.resume(throwing: IntegrationProxyError(message: "Request failed."))
                }
            }
        }
    }
    
    private func makeRequest<T: Codable>(url: URL, body: String, httpMethod: String = "POST", decoder: JSONDecoder = JSONDecoder()) -> T? {
        var r = URLRequest(url: url)
        let creds = "\(config.cloudServerLogin):\(config.cloudServerPassword)".data(using: .utf8)?.base64EncodedString() ?? ""
        r.httpMethod = httpMethod
        r.addValue("application/json", forHTTPHeaderField: "Content-Type")
        r.addValue("Basic \(creds)", forHTTPHeaderField: "authorization")
        r.httpBody = body.data(using: .utf8)!
        var result: T? = nil
        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: r) { data, resp, error in
            if let data = data {
                result = try? decoder.decode(T.self, from: data)
            }
            semaphore.signal()
        }.resume()
        semaphore.wait()
        return result
    }
    
    private func preparePAInstance() -> PowerAuthSDK {
        
        let cfg = PowerAuthConfiguration(
            instanceId: "tests",
            baseEndpointUrl: config.enrollmentServerUrl,
            configuration: config.sdkConfig
        )
        cfg.keychainKey_Biometry = "testsBiometry"
        
        return PowerAuthSDK(configuration: cfg)!
    }
    
    private func enrollPAInstance(pa: PowerAuthSDK, pin: String, callback: @escaping (String?) -> Void) {
        guard let act = createActivation() else {
            callback("Create activation on server failed.")
            return
        }
        registrationId = act.registrationId
        pa.createActivation(withName: "tests", activationCode: act.activationCode()!) { result, error in
            guard let _ = result else {
                callback("Create activation failed.")
                return
            }
            do {
                try pa.persistActivation(withPassword: pin)
            } catch _ {
                callback("Commit activation locally failed.")
                return
            }
            guard let _ = self.commitActivationOnServer(registrationId: act.registrationId) else {
                callback("Commit on server failed.")
                return
            }
            callback(nil)
        }
    }
    
    private func createActivation() -> RegistrationObject? {
        let body = """
        {
          "userId": "\(activationName)",
          "flags": [],
          "appId": "\(config.cloudApplicationId)"
        }
        """
        let resp: RegistrationObject? = makeRequest(url: URL(string: "\(config.cloudServerUrl)/v2/registrations")!, body: body)
        return resp
    }
    
    private func commitActivationOnServer(registrationId: String) -> CommitObject? {
        let body = """
        {
          "externalUserId": "test"
        }
        """
        let resp: CommitObject? = makeRequest(url: URL(string: "\(config.cloudServerUrl)/v2/registrations/\(registrationId)/commit")!, body: body)
        return resp
    }
    
    func getOIDCProviders() -> OIDCProperties? {
        guard let providerId = config.oidcProviderId, let providerIdPkce = config.oidcProviderIdPkce else { return nil
        }
        return OIDCProperties(providerId: providerId, providerIdPkce: providerIdPkce)
    }
}

private struct RegistrationObject: Codable {
    let activationQrCodeData: String
    let registrationId: String
    
    func activationCode() -> String? { return PowerAuthActivationCodeUtil.parse(fromActivationCode: activationQrCodeData)?.activationCode }
}

private struct CommitObject: Codable {
    let status: String
}

struct CancelObject: Codable {
    let status: String
}

struct OperationObject: Codable {
    let operationId: String
    let userId: String?
    let status: String
    let operationType: String
    // let parameters: [String: Any]? // Decoded but not used in tests
    let failureCount: Int
    let maxFailureCount: Int
    let timestampCreated: Int
    let timestampExpires: Int
    let proximityOtp: String?
    /// Additional data is dictionary of [String: Any] but we use TestAdditionalData for tests to be able to decode it in non-generic way
    /// if you need any more specific data, you can add it to TestAdditionalData
    let additionalData: TestAdditionalData?
}

struct TestAdditionalData: Codable {
    let mobileTokenData: TestMobileTokenData?
}

struct TestMobileTokenData: Codable {
    let test1: Int?
    let test2: Double?
    let test3: String?
    let test4: [String: Bool]?
    
    let preApprovalScreens: [TestPreApprovalVisit]?
    let customRecord: CustomRecordData?
}

struct TestPreApprovalVisit: Codable {
    let screen: String?
    let timestampOpened: String?
    let timestampClosed: String?
    let action: String?
}

struct CustomRecordData: Codable {
    let flag: Bool?
    let mode: String?
}

private struct IntegrationConfig: Codable {
    let cloudServerUrl: String
    let cloudServerLogin: String
    let cloudServerPassword: String
    let cloudApplicationId: String
    let enrollmentServerUrl: String
    let operationsServerUrl: String
    let inboxServerUrl: String
    let pushServerUrl: String
    let sdkConfig: String
    let oidcProviderId: String?
    let oidcProviderIdPkce: String?
}

struct QROperationData: Codable {
    let operationQrCodeData: String
    let nonce: String
}

struct QROperationVerify: Codable {
    let otpValid: Bool
    let userId: String
    let registrationId: String
    let registrationStatus: String
    let signatureType: String
    let remainingAttempts: Int
    // let flags: []
    // let application
}

struct InboxMessage: Codable {
    let subject: String
    let summary: String
    let body: String
    let type: String
}

struct InboxMessageDetail: Codable {
    let id: String
    let subject: String
    let summary: String
    let body: String
    let type: String
    let timestamp: Date
    let read: Bool
}

struct OIDCProperties {
    let providerId: String
    let providerIdPkce: String
}

struct IntegrationProxyError: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}

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
