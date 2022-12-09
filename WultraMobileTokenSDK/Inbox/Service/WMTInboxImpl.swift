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
import PowerAuth2
import WultraPowerAuthNetworking

public extension PowerAuthSDK {
    /// Creates instance of the `WMTInbox` on top of the PowerAuth instance.
    /// - Parameters:
    ///   - networkingConfig: Networking service config
    /// - Returns: Inbox service
    func createWMTInbox(networkingConfig: WPNConfig) -> WMTInbox {
        return WMTInboxImpl(networking: WPNNetworkingService(powerAuth: self, config: networkingConfig, serviceName: "WMTInbox"))
    }
}

public extension WPNNetworkingService {
    /// Creates instance of the `WMTInbox` on top of the WPNNetworkingService instance.
    /// - Returns: Inbox service
    func createWMTInbox() -> WMTInbox {
        return WMTInboxImpl(networking: self)
    }
}

class WMTInboxImpl: WMTInbox, WMTService {
    
    // Dependencies
    lazy var powerAuth = networking.powerAuth
    private let networking: WPNNetworkingService
    
    var acceptLanguage: String {
        get { networking.acceptLanguage }
        set { networking.acceptLanguage = newValue }
    }
    
    init(networking: WPNNetworkingService) {
        self.networking = networking
    }
    
    func getUnreadCount(completion: @escaping (Result<WMTInboxCount, WMTError>) -> Void) -> Operation? {
        guard validateActivation(completion) else {
            return nil
        }
        
        return networking.post(data: .init(), signedWith: .possession(), to: WMTInboxEndpoints.Count.endpoint) { [weak self] response, error in
            self?.processResult(response: response, error: error, completion: completion)
        }
    }
    
    func getMessageList(pageNumber: Int, pageSize: Int, onlyUnread: Bool, completion: @escaping (Result<[WMTInboxMessage], WMTError>) -> Void) -> Operation? {
        guard validateActivation(completion) else {
            return nil
        }
        let data = WMTInboxGetList(page: pageNumber, size: pageSize, onlyUnread: onlyUnread)
        return networking.post(data: .init(data), signedWith: .possession(), to: WMTInboxEndpoints.MessageList.endpoint) { [weak self] response, error in
            self?.processResult(response: response, error: error, completion: completion)
        }
    }
    
    func getMessageDetail(messageId: String, completion: @escaping (Result<WMTInboxMessageDetail, WMTError>) -> Void) -> Operation? {
        guard validateActivation(completion) else {
            return nil
        }
        let data = WMTInboxGetMessageDetail(id: messageId)
        return networking.post(data: .init(data), signedWith: .possession(), to: WMTInboxEndpoints.MessageDetail.endpoint) { [weak self] response, error in
            self?.processResult(response: response, error: error, completion: completion)
        }
    }
    
    func markRead(messageId: String, completion: @escaping (Result<Void, WMTError>) -> Void) -> Operation? {
        guard validateActivation(completion) else {
            return nil
        }
        let data = WMTInboxSetMessageRead(id: messageId)
        return networking.post(data: .init(data), signedWith: .possession(), to: WMTInboxEndpoints.MessageRead.endpoint) { [weak self] response, error in
            self?.processResult(response: response, error: error, completion: completion)
        }
    }
    
    func markAllRead(completion: @escaping (Result<Void, WMTError>) -> Void) -> Operation? {
        guard validateActivation(completion) else {
            return nil
        }
        return networking.post(data: .init(), signedWith: .possession(), to: WMTInboxEndpoints.MessageReadAll.endpoint) { [weak self] response, error in
            self?.processResult(response: response, error: error, completion: completion)
        }
    }
}
