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

/// A class returned as Error from the library interfaces.
public class WMTError: Error {
    
    init(reason: WMTErrorReason, error: Error? = nil) {
        #if DEBUG
        WMTError.validateNestedError(error)
        #endif
        self.reason = reason
        self.nestedError = error
    }
    
    /// Private initializer
    fileprivate init(reason: WMTErrorReason,
                     nestedError: Error?,
                     httpStatusCode: Int,
                     httpUrlResponse: HTTPURLResponse?,
                     restApiError: RestApiError?) {
        self.nestedError = nestedError
        self.reason = reason
        self._httpStatusCode = httpStatusCode
        self.httpUrlResponse = httpUrlResponse
        self.restApiError = restApiError
    }
    
    #if DEBUG
    private static func validateNestedError(_ error: Error?) {
        if let error = error as? WMTError {
            D.error("You should not embed WMTError into another WMTError object. Please use .wrap() function if you're not sure what type of error is passed to initializer. Error: \(error.localizedDescription)")
        }
    }
    #endif
    
    
    // MARK: - Properties
    
    /// Reason why the error was created
    public let reason: WMTErrorReason
    
    /// Nested error.
    public let nestedError: Error?
    
    /// HTTP status code.
    ///
    /// If value is not set, then it is automatically gathered from
    /// the nested error or from `URLResponse`. Also the nested error must be produced
    /// in PowerAuth2 library and contain embedded `PA2ErrorResponse` object.
    ///
    /// Due to internal getter optimization, the nested objects evaluation is performed only once.
    /// So if you get the value before URL response is set, then the returned value will be incorrect.
    /// You can still later override the calculated value by setting a new one.
    public var httpStatusCode: Int {
        set {
            _httpStatusCode = newValue
        }
        get {
            if _httpStatusCode >= 0 {
                return _httpStatusCode
            } else if let httpUrlResponse = httpUrlResponse {
                _httpStatusCode = Int(httpUrlResponse.statusCode)
            } else if let responseObject = self.powerAuthErrorResponse {
                _httpStatusCode = Int(responseObject.httpStatusCode)
            } else {
                _httpStatusCode = 0
            }
            return _httpStatusCode
        }
    }
    
    /// Private value for httpStatusCode property.
    private var _httpStatusCode: Int = -1
    
    /// A full response received from the server.
    ///
    /// If you set a valid object to this property, then the `httpStatusCode` starts
    /// returning status code from the response. You can set this value in cases that,
    /// it's important to investigate a whole response, after the authentication fails.
    ///
    /// Normally, setting `httpStatusCode` is enough for proper handling authentication errors.
    public var httpUrlResponse: HTTPURLResponse?
    
    /// An optional error describing details about REST API failure.
    public var restApiError: RestApiError?
}

// MARK: - Wrapping Error into WMTError

public extension WMTError {
    
    /// Returns WMTError object with nested error and additional nested description.
    /// If the provided error object is already WMTError, then returns copy of the object,
    /// with modiffied nested description.
    static func wrap(_ reason: WMTErrorReason, _ error: Error? = nil) -> WMTError {
        if let error = error as? WMTError {
            return WMTError(
                reason: reason,
                nestedError: error.nestedError,
                httpStatusCode: error._httpStatusCode,
                httpUrlResponse: error.httpUrlResponse,
                restApiError: error.restApiError)
        }
        return WMTError(reason: reason, error: error)
    }
}

public struct WMTErrorReason: RawRepresentable, Equatable, Hashable {
    
    public static let missingActivation = WMTErrorReason(rawValue: "missingActivation")
    public static let unknown = WMTErrorReason(rawValue: "unknown")
    
    public typealias RawValue = String
    public var rawValue: RawValue
    public var hashValue: Int { return rawValue.hashValue }
    
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
}

// MARK: - Computed properties

public extension WMTError {
    
    /// A fallback domain identifier which is returned in situations, when the nested error
    /// is not set, or if it's not kind of NSError object.
    static let domain = "WMTError"
    
    
    /// If nestedError is valid, then returns its code
    var code: Int {
        guard let e = nestedError as NSError? else {
            return 0
        }
        return e.code
    }
    
    /// If nestedError is valid, then returns its domain.
    /// Otherwise returns `WMTError.domain`
    var domain: String {
        guard let e = nestedError as NSError? else {
            return WMTError.domain
        }
        return e.domain
    }
    
    /// If nestedError is valid, then returns its user info.
    var userInfo: [String:Any] {
        guard let e = nestedError as NSError? else {
            return [:]
        }
        return e.userInfo
    }
    
    /// Returns true if nested error has information about missing network connection.
    /// The device is typically not connected to the internet.
    var networkIsNotReachable: Bool {
        if self.domain == NSURLErrorDomain || self.domain == kCFErrorDomainCFNetwork as String {
            let ec = CFNetworkErrors(rawValue: Int32(self.code))
            return ec == .cfurlErrorNotConnectedToInternet ||
                ec == .cfurlErrorInternationalRoamingOff ||
                ec == .cfurlErrorDataNotAllowed
        }
        return false
    }
    
    /// Returns true if nested error has information about connection security, like untrusted TLS
    /// certificate, or similar TLS related problems.
    var networkConnectionIsNotTrusted: Bool {
        let domain = self.domain
        if domain == NSURLErrorDomain || domain == kCFErrorDomainCFNetwork as String {
            let code = Int32(self.code)
            if code == CFNetworkErrors.cfurlErrorServerCertificateHasBadDate.rawValue ||
                code == CFNetworkErrors.cfurlErrorServerCertificateUntrusted.rawValue ||
                code == CFNetworkErrors.cfurlErrorServerCertificateHasUnknownRoot.rawValue ||
                code == CFNetworkErrors.cfurlErrorServerCertificateNotYetValid.rawValue ||
                code == CFNetworkErrors.cfurlErrorSecureConnectionFailed.rawValue {
                return true
            }
        }
        return false
    }
    
    /// Returns `PA2ErrorResponse` if such object is embedded in nested error. This is typically useful
    /// for getting response created in the PowerAuth2 library.
    var powerAuthErrorResponse: PA2ErrorResponse? {
        if let responseObject = self.userInfo[PA2ErrorDomain] as? PA2ErrorResponse {
            return responseObject
        }
        return nil
    }
    
    
    var powerAuthRestApiErrorCode: String? {
        if let response = restApiError {
            return response.code
        }
        if let code = powerAuthErrorResponse?.responseObject?.code {
            return code
        }
        return nil
    }
}

extension WMTError: CustomStringConvertible {
    public var description: String {
        
        if let nsne = nestedError as NSError? {
            return nsne.description
        }
        
        var result = "Error reason: \(reason)"
        
        result += "\nError  domain: \(domain), code: \(code)"
        
        if httpStatusCode != -1 {
            result += "\nHTTP Status Code: \(httpStatusCode)"
        }
        
        if let raec = powerAuthRestApiErrorCode {
            result += "\nPA REST API Code: \(raec)"
        }
        
        return result
    }
}

extension D {
    static func error(_ error: @autoclosure ()->WMTError) {
        D.error(error().description)
    }
}

