//
//  WhiteLabelChatTests.swift
//  WhiteLabelChatTests
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import XCTest
@testable import WhiteLabelChat

private let ServerURL = NSURL(string: "http://172.16.30.159:3000")!
private let APICallTimeout: NSTimeInterval = 30.0

var currentUser: User!
var chatController = ChatController(chatServerURL: ServerURL)
let roomUUID = NSUUID()

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
	private let username = "unittest"
	private let password = "unittest"
	
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
	
	func testA_createOrLoginUnitTestAccount() {
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
	
	func testB_cantJoinRoom() {
		XCTAssertThrows(ErrorCode.NotConnected, message: "Join room should fail because the user is not connected yet") {
			try chatController.joinRoom(roomUUID: roomUUID) { (room, error) -> () in
				XCTFail("This shouldn't be called")
			}
		}
	}
	
	func testC_connectToChat() {
		let expectation = expectationWithDescription("connectWithUser should post ChatControllerDidConnectNotification")
		NSNotificationCenter.defaultCenter().addObserverForName(ChatControllerDidConnectNotification, object: chatController, queue: NSOperationQueue()) { (notification) -> Void in
			expectation.fulfill()
		}
		
		var finished = false
		
		chatController.connectWithUser(currentUser, timeout: Int(APICallTimeout)) { (error) -> () in
			XCTAssertNil(error)
			
			finished = true
		}
		
		while !finished {
			NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
		}
		
		waitForExpectationsWithTimeout(1.0) { (error) -> Void in
			if let error = error {
				print(error)
			}
		}
	}
	
	func testD_joinRoomNoUserPhoto() {
		XCTAssertThrows(ErrorCode.RequiresUserPhoto, message: "Join room should fail because the user doesn't have a photo") {
			try chatController.joinRoom(roomUUID: roomUUID) { (room, error) -> () in
				XCTFail("This shouldn't be called")
			}
		}
	}
	
	func testE_joinRoom() {
		var finished = false
		
		currentUser.userPhoto = NSURL(string: "http://fueled.com")
		XCTAssertNoThrow("Join room should succeed", failureAction: {
			finished = true
		}) {
			try chatController.joinRoom(roomUUID: roomUUID) { (room, error) -> () in
				defer { finished = true }
				
				XCTAssertNil(error)
				XCTAssertNotNil(room)
				
				guard let room = room else {
					return
				}
				
				XCTAssertEqual(room.roomID, roomUUID)
				XCTAssertEqual(room.messages.count, 0)
			}
		}
		
		while !finished {
			NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
		}
	}
	
	func testF_sendMessage() {
		let expectation = expectationWithDescription("sendMessage should post ChatControllerReceivedNewMessageNotification")
		
		var object: NSObjectProtocol!
		var finished = false
		
		currentUser.userPhoto = NSURL(string: "http://fueled.com")
		XCTAssertNoThrow("Join room should succeed", failureAction: {
			finished = true
		}) {
			let testMessageContent = "Test Message \(arc4random())"
			try chatController.sendMessage(testMessageContent, roomUUID: roomUUID) { (message, error) -> () in
				var once = true
				object = NSNotificationCenter.defaultCenter().addObserverForName(ChatControllerReceivedNewMessageNotification, object: chatController, queue: NSOperationQueue()) { (notification) -> Void in
					defer {	expectation.fulfill() }
					
					XCTAssertNotNil(notification.userInfo?[ChatControllerMessageNotificationKey] as? Message)
					
					guard let message = notification.userInfo?[ChatControllerMessageNotificationKey] as? Message else {
						return
					}
					
					XCTAssertEqual(message.sender.username, currentUser.username)
					XCTAssertEqual(message.content, testMessageContent)
				}
				
				XCTAssertNil(error)
				XCTAssertNotNil(message)
				
				guard let message = message else {
					finished = true
					return
				}
				
				XCTAssertEqual(message.sender.username, currentUser.username)
				XCTAssertEqual(message.content, testMessageContent)
				
				XCTAssertNoThrow("Join room should succeed", failureAction: {
					finished = true
				}) {
					try chatController.messagesInRoom(roomUUID: roomUUID) { (messages, error) -> () in
						defer { finished = true }
						
						XCTAssertNil(error)
						XCTAssertNotNil(messages)
						
						guard let messages = messages else {
							return
						}
						
						XCTAssertEqual(messages.count, 1)
						
						guard let lastMessage = messages.first else {
							return
						}
						
						XCTAssertEqual(lastMessage.sender.username, currentUser.username)
						XCTAssertEqual(lastMessage.content, testMessageContent)
					}
				}
			}
		}
		
		while !finished {
			NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
		}
		
		waitForExpectationsWithTimeout(APICallTimeout) { (error) -> Void in
			if let error = error {
				print(error)
			}
		}
		
		NSNotificationCenter.defaultCenter().removeObserver(object)
	}
	
	func testG_sendMessageWithMultipleClient() {
		let expectation = expectationWithDescription("sendMessage should post ChatControllerReceivedNewMessageNotification twice")
		
		var object: NSObjectProtocol!
		var finished = false
		
		var randomUserChatControllerStorage: ChatController!
		self.signUpWithRandomUser { (randomUserChatController) -> () in
			randomUserChatControllerStorage = randomUserChatController
			
			let testMessageContent = "Test Message \(arc4random())"
			var calledCount = 0
			object = NSNotificationCenter.defaultCenter().addObserverForName(ChatControllerReceivedNewMessageNotification, object: nil, queue: NSOperationQueue()) { (notification) -> Void in
				defer {
					if(++calledCount == 2) {
						expectation.fulfill()
						finished = true
					}
				}
				
				XCTAssertNotNil(notification.userInfo?[ChatControllerMessageNotificationKey] as? Message)
				
				guard let message = notification.userInfo?[ChatControllerMessageNotificationKey] as? Message else {
					return
				}
				
				XCTAssertEqual(message.sender.username, randomUserChatController.connectedUser?.username)
				XCTAssertEqual(message.content, testMessageContent)
			}
			
			XCTAssertNoThrow("Join room should succeed") {
				try randomUserChatController.joinRoom(roomUUID: roomUUID) { (room, error) in
					XCTAssertNoThrow("Send message should succeed") {
						try randomUserChatController.sendMessage(testMessageContent, roomUUID: roomUUID) { (message, error) in
							XCTAssertNil(error)
							XCTAssertNotNil(message)
							
							guard let message = message else {
								return
							}
							
							XCTAssertEqual(message.sender.username, randomUserChatController.connectedUser?.username)
							XCTAssertEqual(message.content, testMessageContent)
						}
					}
				}
			}
		}
		
		waitForExpectationsWithTimeout(APICallTimeout) { (error) -> Void in
			if let error = error {
				print(error)
			}
			finished = true
		}
		
		while !finished {
			NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
		}
		
		NSNotificationCenter.defaultCenter().removeObserver(object)
	}
	
	func signUpWithRandomUser(completionHandler: (randomUserChatController: ChatController) -> ()) {
		let username = "test\(arc4random())"
		let password = "test\(arc4random())"
		User.registerWithUsername(username, password: password) { (user, error) -> () in
			User.loginWithUsername(username, password: password) { (user, error) -> () in
				let chatController = ChatController()
				user!.userPhoto = NSURL(string: "http://fueled.com")
				chatController.connectWithUser(user!, timeout: 0) { (error) -> () in
					completionHandler(randomUserChatController: chatController)
				}
			}
		}
	}
	
	func testH_disconnectAndSendMessage() {
		let expectation = expectationWithDescription("disconnect should post ChatControllerDidDisconnectNotification")
		NSNotificationCenter.defaultCenter().addObserverForName(ChatControllerDidDisconnectNotification, object: chatController, queue: NSOperationQueue()) { (notification) -> Void in
			expectation.fulfill()
		}
		chatController.disconnect()
		XCTAssertThrows(ErrorCode.NotConnected, message: "Join room should fail because the user disconnected") {
			try chatController.joinRoom(roomUUID: roomUUID) { (room, error) -> () in
				XCTFail("This shouldn't be called")
			}
		}
		waitForExpectationsWithTimeout(APICallTimeout) { (error) -> Void in
			if let error = error {
				print(error)
			}
		}
	}
}
