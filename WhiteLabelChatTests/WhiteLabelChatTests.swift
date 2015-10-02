//
//  WhiteLabelChatTests.swift
//  WhiteLabelChatTests
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import XCTest
@testable import WhiteLabelChat

private let APICallTimeout = 30.0

var currentUser: User!

class WhiteLabelChatTests: XCTestCase {
	private let username = "unittest"
	private let password = "unittest"
	
	private var chatController: ChatController!
	
	override func setUp() {
		Configuration.defaultBaseURL = NSURL(string: "http://172.16.30.159:3000/")
		
		self.chatController = ChatController()
	}
	
	override func tearDown() {
		self.chatController = nil
	}
	
	func testAAAAA_CreateOrLoginUnitTestAccount() {
		var finished = false
		
		User.registerWithUsername(self.username, password: self.password) { (user, error) -> () in
			if let user = user {
				currentUser = user
				
				finished = true
			} else {
				User.loginWithUsername(self.username, password: self.password) { (user, error) -> () in
					currentUser = user
					
					finished = true
				}
			}
		}
		
		while !finished {
			NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
		}
		
		XCTAssertNotNil(currentUser.authToken)
		
		if let authToken = currentUser.authToken {
			print("Current authenticated token: \(authToken)")
		}
	}
	
	func testUserSignUp() {
		let username = "test\(arc4random())"
		let password = "test\(arc4random())"
		let expectation = expectationWithDescription("Register & Login successfully")
		User.registerWithUsername(username, password: password) { (user, error) -> () in
			XCTAssertNotNil(user)
			XCTAssertNil(error)
			guard let user = user else {
				return
			}
			XCTAssertEqual(user.username, username)
			XCTAssertTrue(user.isAuthenticated)
			
			User.loginWithUsername(username, password: password) { (user, error) -> () in
				expectation.fulfill()
				
				XCTAssertNotNil(user)
				XCTAssertNil(error)
				
				guard let user = user else {
					return
				}
				
				XCTAssertEqual(user.username, username)
				XCTAssertTrue(user.isAuthenticated)
			}
		}
		waitForExpectationsWithTimeout(APICallTimeout) { (error) -> Void in
			if let error = error {
				print(error)
			}
		}
	}
	
	func testUserInvalidRequestLogin() {
		let expectation = expectationWithDescription("Login fails because of a validation error")
		User.loginWithUsername("*&$^#!", password: "fueled") { (user, error) -> () in
			XCTAssertNil(user)
			XCTAssertNotNil(error)
			switch(error!) {
			case ErrorCode.RequestFailed:
				break
			default:
				XCTFail("error is not \(ErrorCode.RequestFailed)")
			}
			
			expectation.fulfill()
		}
		waitForExpectationsWithTimeout(APICallTimeout) { (error) -> Void in
			if let error = error {
				print(error)
			}
		}
	}
}
