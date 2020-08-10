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

class IntegrationUtils {
    
    private static var config: IntegrationConfig!
    private static let paUrl = config.paServerUrl
    private static let activationName = "mtokenSdkIosTests"
    
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
                let wmtconf = WMTConfig(baseUrl: URL(string: config.operationsServerUrl)!, sslValidation: .noValidation)
                callback((pa,pa.createWMTOperations(config: wmtconf)), nil)
            }
        }
    }
    
    class func createOperation(knowledge: Bool, completion: @escaping (String?) -> Void) {
        DispatchQueue.global().async {
            let opBody: String
            if !knowledge {
                opBody = """
                {
                    "requestObject": {
                        "operationName": "login_sca",
                        "operationData": "A2",
                        "formData": {
                          "title": {
                            "id": "login.title"
                          },
                          "greeting": {
                            "id": "login.greeting"
                          },
                          "summary": {
                            "id": "login.summary"
                          }
                        }
                    }
                }
                """
            } else {
                opBody = """
                {
                  "requestObject": {
                    "operationName": "authorize_payment",
                    "operationId": null,
                    "operationData": "A1*A100CZK*Q238400856/0300**D20170629*NUtility Bill Payment - 05/2017",
                    "params": [],
                    "formData": {
                      "title": {
                        "id": "operation.title",
                        "value": "Charge karta"
                      },
                      "greeting": {
                        "id": "operation.greeting",
                        "value": "Hello"
                      },
                      "summary": {
                        "id": "operation.summary",
                        "value": "Potvrďte platbu."
                      },
                      "config": [],
                      "parameters": [
                        {
                          "type": "AMOUNT",
                          "id": "operation.amount",
                          "label": null,
                          "valueFormatType": "AMOUNT",
                          "formattedValue": null,
                          "amount": 10000000000.99,
                          "currency": "EUR",
                          "currencyId": "operation.currency"
                        },
                        {
                          "type": "HEADING",
                          "id": "operation.heading",
                          "label": "Nadpis",
                          "valueFormatType": "TEXT",
                          "formattedValue": null,
                          "value": "000000-25000377732500037773037773/5800"
                        },
                        {
                          "type": "KEY_VALUE",
                          "id": "operation.account",
                          "label": null,
                          "valueFormatType": "ACCOUNT",
                          "formattedValue": null,
                          "value": "test test test"
                        }
                      ],
                      "dynamicDataLoaded": false,
                      "userInput": {}
                    }
                  }
                }
                """
            }
            
            // step1: create an operation on the nextstep server
            guard let op: PAObject<PAOperationCreateObject> = self.makeRequest(url: URL(string: "\(config.nextStepServerUrl)/operation")!, body: opBody) else {
                completion("Failed to create operation on the server.")
                return
            }
            
            let assignBody = """
            {
              "requestObject": {
                "operationId": "\(op.responseObject.operationId)",
                "userId": "\(activationName)",
                "organizationId": "RETAIL",
                "accountStatus": "ACTIVE"
              }
            }
            """
            
            // step2: assign the operation to the user
            guard let _: PASimpleObject = self.makeRequest(url: URL(string: "\(config.nextStepServerUrl)/operation/user/update")!, body: assignBody) else {
                
                completion("Failed to assign the operation to the user.")
                return
            }
            
            // step3: if the operation needs to be authorized with
            // a knowledge, move it to the "confirmed" state
            if knowledge {
                let b = """
                {
                  "requestObject": {
                    "operationId": "\(op.responseObject.operationId)",
                    "userId": "\(activationName)",
                    "organizationId": "RETAIL",
                    "authMethod": "USER_ID_ASSIGN",
                    "authStepResult": "CONFIRMED",
                    "authStepResultDescription": null,
                    "params": []
                  }
                }
                """
                guard let _: PASimpleObject = self.makeRequest(url: URL(string: "\(config.nextStepServerUrl)/operation/update")!, body: b) else {
                    completion("Failed to update operation to the next state")
                    return
                }
            }
            
            // step4: make the op "approvable" by the mobile token
            guard let _: PASimpleObject = self.makeRequest(url: URL(string: "\(config.nextStepServerUrl)/operation/mobileToken/status/update")!, body:
                """
                {
                  "requestObject": {
                    "operationId": "\(op.responseObject.operationId)",
                    "mobileTokenActive": true
                  }
                }
                """) else {
                    completion("Failed to set mobileTokenActive.")
                    return
            }
            
            // step5: step auth method to the operation
            guard let _: PASimpleObject = self.makeRequest(url: URL(string: "\(config.nextStepServerUrl)/operation/chosenAuthMethod/update")!, body: """
                {
                  "requestObject": {
                    "operationId": "\(op.responseObject.operationId)",
                    "chosenAuthMethod": "\(knowledge ? "POWERAUTH_TOKEN" : "LOGIN_SCA")"
                  }
                }
                """) else {
                    completion("Failed to update auth method.")
                    return
            }
            
            // if everything went OK, return with empty error
            completion(nil)
        }
    }
    
    private class func makeRequest<T: Codable>(url: URL, body: String) -> T? {
        var r = URLRequest(url: url)
        r.httpMethod = "POST"
        r.addValue("application/json", forHTTPHeaderField: "Content-Type")
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
        pa.createActivation(withName: "tests", activationCode: act.responseObject.activationCode) { result, error in
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
            guard let _ = commitActivationOnServer(activationId: act.responseObject.activationId) else {
                callback("Commit on server failed.")
                return
            }
            guard let _ = makeActivationPrimary(activationId: act.responseObject.activationId) else {
                callback("Make activation primary failed.")
                return
            }
            callback(nil)
        }
    }
    
    private class func createActivation() -> PAObject<PAInitResponseObject>? {
        let body = """
        {
            "requestObject": {
                "activationOtpValidation": "NONE",
                "applicationId": \(config.appId),
                "maxFailureCount": 5,
                "userId": "\(activationName)"
            }
        }
        """
        let resp: PAObject<PAInitResponseObject>? = makeRequest(url: URL(string: "\(paUrl)/rest/v3/activation/init")!, body: body)
        return resp
    }
    
    private class func commitActivationOnServer(activationId: String) -> PAObject<PACommitObject>? {
        let body = """
        {
          "requestObject": {
            "activationId": "\(activationId)"
          }
        }
        """
        let resp: PAObject<PACommitObject>? = makeRequest(url: URL(string: "\(paUrl)/rest/v3/activation/commit")!, body: body)
        return resp
    }
    
    private class func makeActivationPrimary(activationId: String) -> PASimpleObject? {
        let body = """
        {
            "requestObject": {
                "userId": "\(activationName)",
                "authMethod": "POWERAUTH_TOKEN",
                "config": {
                    "activationId": "\(activationId)"
                }
            }
        }
        """
        let resp: PASimpleObject? = makeRequest(url: URL(string: "\(config.nextStepServerUrl)/user/auth-method")!, body: body)
        return resp
    }
}

private struct PASimpleObject: Codable {
    let status: String
}

private struct PAObject<T: Codable>: Codable {
    let responseObject: T
    let status: String
}

private struct PAInitResponseObject: Codable {
    let activationId: String
    let activationCode: String
    let activationSignature: String
    let userId: String
    let applicationId: Int
}

private struct PACommitObject: Codable {
    let activated: Bool
    let activationId: String
}

private struct PAOperationCreateObject: Codable {
    let operationId: String
}

private struct IntegrationConfig: Codable {
    let paServerUrl: String
    let nextStepServerUrl: String
    let enrollmentServerUrl: String
    let operationsServerUrl: String
    let appKey: String
    let appSecret: String
    let masterServerPublicKey: String
    let appId: String
}
