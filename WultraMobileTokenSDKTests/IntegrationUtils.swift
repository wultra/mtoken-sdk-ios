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

import PowerAuth2
import WultraMobileTokenSDK
import WultraPowerAuthNetworking

class IntegrationUtils {
    
    private static var config: IntegrationConfig!
    private static let activationName = UUID().uuidString
    private static var registrationId = "" // will be filled when activation is created
    
    typealias Callback = (_ instances: (PowerAuthSDK, WMTOperations)?, _ error: String?) -> Void
    
    class func prepareActivation(pin: String, callback: @escaping Callback) {
        
        guard let configPath = Bundle.init(for: IntegrationUtils.self).path(forResource: "config", ofType: "json", inDirectory: "Configs") else {
            callback(nil, "Config file config.json is not present.")
            return
        }
        
        do {
            let configContent = try String(contentsOfFile: configPath)
            config = try JSONDecoder().decode(IntegrationConfig.self, from: configContent.data(using: .utf8)!)
        } catch _ {
            callback(nil, "Config file config.json cannot be parsed.")
            return
        }
        
        let pa = preparePAInstance()
        enrollPAInstance(pa: pa, pin: pin) { error in
            if let error = error {
                callback(nil, error)
            } else {
                let wpnConf = WPNConfig(baseUrl: URL(string: config.operationsServerUrl)!, sslValidation: .noValidation)
                callback((pa,pa.createWMTOperations(networkingConfig: wpnConf, pollingOptions: [.pauseWhenOnBackground])), nil)
            }
        }
    }
    
    enum Factors {
        // TODO: temp unsupported
        //case OF_1FA
        case F_2FA
    }
    
    class func createOperation(_ factors: Factors = .F_2FA, completion: @escaping (OperationObject?) -> Void) {
        DispatchQueue.global().async {
            let opBody: String
            switch factors {
            case .F_2FA:
                opBody = """
                {
                  "userId": "\(activationName)",
                  "template": "login-tpp",
                   "parameters": {
                     "party.id": "666",
                     "party.name": "Datová schránka",
                         "session.id": "123",
                         "session.ip-address": "192.168.0.1"
                   }
                }
                """
            }
            
            completion(self.makeRequest(url: URL(string: "\(config.cloudServerUrl)/v2/operations")!, body: opBody))
        }
    }
    
    class func getQROperation(operation: OperationObject, completion: @escaping (QROperationData?) -> Void) {
        DispatchQueue.global().async {
            completion(self.makeRequest(url: URL(string: "\(config.cloudServerUrl)/v2/operations/\(operation.operationId)/offline/qr?registrationId=\(registrationId)")!, body: "", httpMethod: "GET"))
        }
    }
    
    class func verifyQROperation(operation: OperationObject, operationData: QROperationData, otp: String, completion: @escaping (QROperationVerify?) -> Void) {
        DispatchQueue.global().async {
            let body = """
                {
                  "otp": "\(otp)",
                  "nonce": "\(operationData.nonce)",
                  "registrationId": "\(registrationId)"
                }
            """
            completion(self.makeRequest(url: URL(string: "\(config.cloudServerUrl)/v2/operations/\(operation.operationId)/offline/otp")!, body: body))
        }
    }
    
    private class func makeRequest<T: Codable>(url: URL, body: String, httpMethod: String = "POST") -> T? {
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
                result = try? JSONDecoder().decode(T.self, from: data)
            }
            semaphore.signal()
        }.resume()
        semaphore.wait()
        return result
    }
    
    private class func preparePAInstance() -> PowerAuthSDK {
        
        let cfg = PowerAuthConfiguration()
        cfg.instanceId = "tests"
        cfg.baseEndpointUrl = config.enrollmentServerUrl
        cfg.appKey = config.appKey
        cfg.appSecret = config.appSecret
        cfg.masterServerPublicKey = config.masterServerPublicKey
        cfg.keychainKey_Biometry = "testsBiometry"
        
        return PowerAuthSDK(configuration: cfg)!
    }
    
    private class func enrollPAInstance(pa: PowerAuthSDK, pin: String, callback: @escaping (String?) -> Void) {
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
                try pa.commitActivation(withPassword: pin)
            } catch _ {
                callback("Commit activation locally failed.")
                return
            }
            guard let _ = commitActivationOnServer(registrationId: act.registrationId) else {
                callback("Commit on server failed.")
                return
            }
            callback(nil)
        }
    }
    
    private class func createActivation() -> RegistrationObject? {
        let body = """
        {
          "userId": "\(activationName)"
        }
        """
        let resp: RegistrationObject? = makeRequest(url: URL(string: "\(config.cloudServerUrl)/v2/registrations")!, body: body)
        return resp
    }
    
    private class func commitActivationOnServer(registrationId: String) -> CommitObject? {
        let body = """
        {
          "externalUserId": "test"
        }
        """
        let resp: CommitObject? = makeRequest(url: URL(string: "\(config.cloudServerUrl)/v2/registrations/\(registrationId)/commit")!, body: body)
        return resp
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

struct OperationObject: Codable {
    let operationId: String
    let userId: String
    let status: String
    let operationType: String
    //let parameters: [] // not needed for test right now
    let failureCount: Int
    let maxFailureCount: Int
    let timestampCreated: Int
    let timestampExpires: Int
}

private struct IntegrationConfig: Codable {
    let cloudServerUrl: String
    let cloudServerLogin: String
    let cloudServerPassword: String
    let enrollmentServerUrl: String
    let operationsServerUrl: String
    let appKey: String
    let appSecret: String
    let masterServerPublicKey: String
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
