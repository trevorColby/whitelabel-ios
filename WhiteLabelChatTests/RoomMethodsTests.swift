//
//  RoomMethodsTests.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 10/2/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import XCTest
@testable import WhiteLabelChat

class RoomMethodsTests: XCTestCase {
	func testRoomAddMessages() {
		let room = Room(roomID: NSUUID(), numberOfUsers: 0)
		let indexes = room.addMessages(
			[
				Message(messageID: NSUUID(), content: "unused", roomID: room.roomID, sender: User(userID: nil, username: "unused"), dateSent: NSDate(timeIntervalSince1970: 5)),
				Message(messageID: NSUUID(), content: "unused", roomID: room.roomID, sender: User(userID: nil, username: "unused"), dateSent: NSDate(timeIntervalSince1970: 10)),
				Message(messageID: NSUUID(), content: "unused", roomID: room.roomID, sender: User(userID: nil, username: "unused"), dateSent: NSDate(timeIntervalSince1970: 7))
			])
		XCTAssertEqual(indexes, [2, 0, 1])
	}
}
