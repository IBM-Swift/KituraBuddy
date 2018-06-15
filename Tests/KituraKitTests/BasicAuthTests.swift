/**
 * Copyright IBM Corporation 2018
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

#if os(Linux)
import Glibc
#else
import Darwin
#endif

import XCTest
import Foundation
import Kitura
import KituraContracts

@testable import KituraKit


class BasicAuthTests: XCTestCase {
    
    static var allTests: [(String, (BasicAuthTests) -> () throws -> Void)] {
        return [
            ("testBasicAuthClientGet", testBasicAuthClientGet),
            ("testBasicAuthClientGetSingle", testBasicAuthClientGetSingle),
            ("testBasicAuthClientPost", testBasicAuthClientPost),
            ("testBasicAuthClientPostWithIdentifier", testBasicAuthClientPostWithIdentifier),
            ("testBasicAuthClientPut", testBasicAuthClientPut),
            ("testBasicAuthClientPatch", testBasicAuthClientPatch),
            ("testBasicAuthClientDelete", testBasicAuthClientDelete),
            ("testBasicAuthClientDeleteSingle", testBasicAuthClientDeleteSingle),
        ]
    }
    
    private let client = KituraKit.default
    
    override func setUp() {
        super.setUp()
        client.addBasicAuth(username: "John", password: "12345")
        continueAfterFailure = false
        
        let controller = Controller(userStore: initialStore)
        Kitura.addHTTPServer(onPort: 8080, with: controller.router)
        Kitura.start()
        
    }
    
    override func tearDown() {
        Kitura.stop()
        super.tearDown()
    }
    
    func testBasicAuthClientGet() {
        let expectation1 = expectation(description: "A response is received from the server -> array of users")
        
        // Invoke GET operation on library
        client.get("/authusers") { (users: [User]?, error: RequestError?) -> Void in
            guard let users = users else {
                XCTFail("Failed to get users! Error: \(String(describing: error))")
                return
            }
            XCTAssertEqual(users.count, 5)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testBasicAuthClientGetSingle() {
        let expectation1 = expectation(description: "A response is received from the server -> user")
        
        // Invoke GET operation on library
        let id = "1"
        client.get("/authusers", identifier: id) { (user: User?, error: RequestError?) -> Void in
            guard let user = user else {
                XCTFail("Failed to get user! Error: \(String(describing: error))")
                return
            }
            XCTAssertEqual(user, initialStore[id]!)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testBasicAuthClientPost() {
        let expectation1 = expectation(description: "A response is received from the server -> user")
        
        // Invoke POST operation on library
        let newUser = User(id: 5, name: "John Doe")
        
        client.post("/authusers", data: newUser) { (user: User?, error: RequestError?) -> Void in
            guard let user = user else {
                XCTFail("Failed to post user! Error: \(String(describing: error))")
                return
            }
            
            XCTAssertEqual(user, newUser)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testBasicAuthClientPostWithIdentifier() {
        let expectation1 = expectation(description: "A response is received from the server -> user")
        
        // Invoke POST operation on library
        let userId = 5
        let newUser = User(id: userId, name: "John Doe")
        
        client.post("/authusersid", data: newUser) { (id: Int?, user: User?, error: RequestError?) -> Void in
            guard let user = user else {
                XCTFail("Failed to post user! Error: \(String(describing: error))")
                return
            }
            guard let id = id else {
                XCTFail("Failed to receive Identifier back from post")
                return
            }
            
            XCTAssertEqual(user, newUser)
            XCTAssertEqual(userId, id)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testBasicAuthClientPut() {
        let expectation1 = expectation(description: "A response is received from the server -> user")
        
        // Invoke PUT operation on library
        let expectedUser = User(id: 5, name: "John Doe")
        
        client.put("/authusers", identifier: String(expectedUser.id), data: expectedUser) { (user: User?, error: RequestError?) -> Void in
            
            guard let user = user else {
                XCTFail("Failed to put user! Error: \(String(describing: error))")
                return
            }
            
            XCTAssertEqual(user, expectedUser)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testBasicAuthClientPatch() {
        let expectation1 = expectation(description: "A response is received from the server -> user")
        
        let expectedUser = User(id: 4, name: "John Doe")
        
        client.patch("/authusers", identifier: String(describing: expectedUser.id), data: expectedUser) { (user: User?, error: RequestError?) -> Void in
            guard let user = user else {
                XCTFail("Failed to patch user! Error: \(String(describing: error))")
                return
            }
            
            XCTAssertEqual(user, expectedUser)
            
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testBasicAuthClientDeleteSingle() {
        let expectation1 = expectation(description: "No error is received from the server")
        
        // Invoke GET operation on library
        client.delete("/authusers", identifier: "1") { error in
            guard error == nil else {
                XCTFail("Failed to delete user! Error: \(String(describing: error))")
                return
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    // delete tests get executed first and cause get individual user tests to fail as the users have been deleted
    
    func testBasicAuthClientDelete() {
        let expectation1 = expectation(description: "No error is received from the server")
        
        client.delete("/authusers") { error in
            guard error == nil else {
                XCTFail("Failed to delete user! Error: \(String(describing: error))")
                return
            }
            
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testBasicAuthClientGetByQuery() {
        let expectation1 = expectation(description: "A response is received from the server -> array of users")
        
        let myQuery = UserQuery(name: "Mike")
        
        // Invoke GET operation on library
        client.get("/authusersWithQueryParams", query: myQuery) { (users: [User]?, error: RequestError?) -> Void in
            guard let users = users else {
                XCTFail("Failed to get users! Error: \(String(describing: error))")
                return
            }
            XCTAssertEqual(users.count, 2)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
    
    func testBasicAuthClientDeleteByQuery() {
        let expectation1 = expectation(description: "No error is received from the server")
        
        let myQuery = UserQuery(name: "Mike")
        
        client.delete("/authusersWithQueryParams", query: myQuery) { error in
            guard error == nil else {
                XCTFail("Failed to delete users! Error: \(String(describing: error))")
                return
            }
            
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 3.0, handler: nil)
    }
}
