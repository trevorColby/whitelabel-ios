//
//  WhiteLabelChatTests.swift
//  WhiteLabelChatTests
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import XCTest
@testable import WhiteLabelChat

func XCTAssertThrows(_ expectedErrorType: Error? = nil, message: String? = nil, failureAction: (() -> ())? = nil, action: () throws -> ()) {
	do {
		try action()
		
		if let message = message {
			XCTFail(message)
		} else {
			XCTFail()
		}
	} catch {
		if let expectedErrorType = expectedErrorType {
			XCTAssertTrue((error as NSError) == (expectedErrorType as NSError), "expected error type \(expectedErrorType), got \(error)")
		}
		failureAction?()
	}
}

func XCTAssertNoThrow(_ message: String? = nil, failureAction: (() -> ())? = nil, action: () throws -> ()) {
	do {
		try action()
	} catch {
		if let message = message {
			XCTFail("\(message) (got error \(error))")
		} else {
			XCTFail("Got error \(error)")
		}
		failureAction?()
	}
}

class WhiteLabelChatTests: XCTestCase {
	override func setUp() {
		Configuration.defaultBaseURL = ServerURL
	}
	
	func testUserSignUp() {
		let username = "test\(arc4random())"
		let password = "test\(arc4random())"
		let expectation = self.expectation(description: "Register & Login successfully")
		ChatController.registerWithUsername(username, password: password) { (user, error) -> () in
			XCTAssertNotNil(user)
			XCTAssertNil(error)
			guard let user = user else {
				return
			}
			XCTAssertEqual(user.username, username)
			XCTAssertTrue(user.isAuthenticated)
			
			ChatController.loginWithUsername(username, password: password) { (user, error) -> () in
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
		waitForExpectations(timeout: APICallTimeout) { (error) -> Void in
			if let error = error {
				print(error)
			}
		}
	}
	
	func testUserInvalidRequestLogin() {
		let expectation = self.expectation(description: "Login fails because of a validation error")
		ChatController.loginWithUsername("*&$^#!", password: "fueled") { (user, error) -> () in
			XCTAssertNil(user)
			XCTAssertNotNil(error)
			switch(error!) {
			case ErrorCode.requestFailed:
				break
			default:
				XCTFail("error is not \(ErrorCode.requestFailed)")
			}
			
			expectation.fulfill()
		}
		waitForExpectations(timeout: APICallTimeout) { (error) -> Void in
			if let error = error {
				print(error)
			}
		}
	}
}
