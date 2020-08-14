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

import XCTest
import WultraMobileTokenSDK

class PushParserTests: XCTestCase {
    
    func testEmptyUserInfo() {
        XCTAssertNil(WMTPushParser.parseNotification([:]))
    }
    
    func testInitPushValid() {
        let oid = "1", oname = "test", otitle = "title", omessage = "message"
        guard let push = makePush(type: "mtoken.operationInit", id: oid, name: oname, title: otitle, message: omessage, opResult: nil) else {
            XCTFail("Failed to parse valid push.")
            return
        }
        guard case .operationCreated(let id, let name, let content) = push else {
            XCTFail("Expected operation created push.")
            return
        }
        
        XCTAssertEqual(id, oid)
        XCTAssertEqual(name, oname)
        XCTAssertEqual(content?.title, otitle)
        XCTAssertEqual(content?.message, omessage)
    }
    
    func testInitPushValidNoTitle() {
        let oid = "1", oname = "test", otitle: String? = nil, omessage = "message"
        guard let push = makePush(type: "mtoken.operationInit", id: oid, name: oname, title: otitle, message: omessage, opResult: nil) else {
            XCTFail("Failed to parse valid push.")
            return
        }
        guard case .operationCreated(let id, let name, let content) = push else {
            XCTFail("Expected operation created push.")
            return
        }
        
        XCTAssertEqual(id, oid)
        XCTAssertEqual(name, oname)
        XCTAssertNil(content)
    }
    
    func testInitPushValidNoMessage() {
        let oid = "1", oname = "test", otitle = "title", omessage: String? = nil
        guard let push = makePush(type: "mtoken.operationInit", id: oid, name: oname, title: otitle, message: omessage, opResult: nil) else {
            XCTFail("Failed to parse valid push.")
            return
        }
        guard case .operationCreated(let id, let name, let content) = push else {
            XCTFail("Expected operation created push.")
            return
        }
        
        XCTAssertEqual(id, oid)
        XCTAssertEqual(name, oname)
        XCTAssertNil(content)
    }
    
    func testInitPushMissingId() {
        XCTAssertNil(makePush(type: "mtoken.operationInit", id: nil, name: "name", title: nil, message: nil, opResult: nil))
    }
    
    func testInitPushMissingName() {
        XCTAssertNil(makePush(type: "mtoken.operationInit", id: "1", name: nil, title: nil, message: nil, opResult: nil))
    }
    
    func testFinishPushValid() {
        let results = [
            "authentication.success": WMTPushOperationFinishedResult.success,
            "authentication.fail": .fail,
            "operation.timeout": .timeout,
            "operation.canceled": .canceled,
            "operation.methodNotAvailable": .methodNotAvailable,
            "nonextistingreason": .unknown
        ]
        for (value, expectedResult) in results {
            let oid = "1", oname = "test"
            guard let push = makePush(type: "mtoken.operationFinished", id: oid, name: oname, title: nil, message: nil, opResult: value) else {
                XCTFail("Failed to parse valid push.")
                return
            }
            guard case .operationFinished(let id, let name, let result) = push else {
                XCTFail("Expected operation finished push.")
                return
            }
            
            XCTAssertEqual(id, oid)
            XCTAssertEqual(name, oname)
            XCTAssertEqual(result, expectedResult)
        }
    }
    
    func testFinishPushMissingResult() {
        XCTAssertNil(makePush(type: "mtoken.operationFinished", id: "1", name: "name", title: nil, message: nil, opResult: nil))
    }
    
    func testFinishPushMissingId() {
        XCTAssertNil(makePush(type: "mtoken.operationFinished", id: nil, name: "name", title: nil, message: nil, opResult: nil))
    }
    
    func testFinishPushMissingName() {
        XCTAssertNil(makePush(type: "mtoken.operationFinished", id: "1", name: nil, title: nil, message: nil, opResult: nil))
    }
    
    // helper methods
    
    private func makePush(type: String?, id: String?, name: String?, title: String?, message: String?, opResult: String?) -> WMTPushMessage? {
        var userInfo = [AnyHashable: Any]()
        userInfo["messageType"] = type
        userInfo["operationId"] = id
        userInfo["operationName"] = name
        userInfo["aps"] = ["alert": ["title": title, "body": message]]
        userInfo["mtokenOperationResult"] = opResult
        return WMTPushParser.parseNotification(userInfo)
    }
}
