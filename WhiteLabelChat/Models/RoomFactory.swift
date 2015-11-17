//
//  RoomFactory.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/30/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

private class DefaultRoom: Room {
	class func newInstance(roomID roomID: NSUUID, numberOfUsers: Int?, messages: [Message]?) -> Room {
		return DefaultRoom(roomID: roomID, numberOfUsers: numberOfUsers, messages: messages)
	}
	
	init(roomID: NSUUID, numberOfUsers: Int?, messages: [Message]?) {
		self.roomID = roomID
		self.numberOfUsers = numberOfUsers
		self.arrayOfMessages = messages ?? []
	}
	
	var roomID: NSUUID
	var numberOfUsers: Int?
	// Post-Condition: the messages are always sorted. First object is the latest message
	let arrayOfMessages: [Message]
}

public class RoomFactory {
	private var registeredClass: Room.Type?
	public static let sharedFactory = RoomFactory()
	
	private init() {
		
	}
	
	public func registerClass(`class`: Room.Type) {
		self.registeredClass = `class`
	}
	
	public func instanciate(roomID roomID: NSUUID, numberOfUsers: Int?, messages: [Message]?) -> Room {
		let classType = self.registeredClass ?? DefaultRoom.self
		return classType.newInstance(roomID: roomID, numberOfUsers: numberOfUsers, messages: messages)
	}
}
