//
//  WhiteLabelChatTests.swift
//  WhiteLabelChatTests
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import XCTest
@testable import WhiteLabelChat

func XCTAssertThrows(expectedErrorType: ErrorType? = nil, message: String? = nil, failureAction: (() -> ())? = nil, @noescape action: () throws -> ()) {
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

func XCTAssertNoThrow(message: String? = nil, failureAction: (() -> ())? = nil, @noescape action: () throws -> ()) {
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
