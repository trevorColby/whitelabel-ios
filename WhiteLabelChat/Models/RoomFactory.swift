//
//  RoomFactory.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/30/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

private class DefaultRoom: Room {
	class func newInstance(roomID: UUID, numberOfUsers: Int?, messages: [Message]?) -> Room {
		return DefaultRoom(roomID: roomID, numberOfUsers: numberOfUsers, messages: messages)
	}
	
	init(roomID: UUID, numberOfUsers: Int?, messages: [Message]?) {
		self.roomID = roomID
		self.numberOfUsers = numberOfUsers
		self.arrayOfMessages = messages ?? []
	}
	
	var roomID: UUID
	var numberOfUsers: Int?
	// Post-Condition: the messages are always sorted. First object is the latest message
	let arrayOfMessages: [Message]
}

open class RoomFactory {
	fileprivate var registeredClass: Room.Type?
	open static let sharedFactory = RoomFactory()
	
	fileprivate init() {
		
	}
	
	open func registerClass(_ class: Room.Type) {
		self.registeredClass = `class`
	}
	
	open func instanciate(roomID: UUID, numberOfUsers: Int?, messages: [Message]?) -> Room {
		let classType = self.registeredClass ?? DefaultRoom.self
		return classType.newInstance(roomID: roomID, numberOfUsers: numberOfUsers, messages: messages)
	}
}
