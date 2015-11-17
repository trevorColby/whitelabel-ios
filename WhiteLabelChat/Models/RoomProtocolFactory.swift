//
//  RoomProtocolFactory.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/30/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

private class Room: RoomProtocol {
	class func newInstance(roomID roomID: NSUUID, numberOfUsers: Int?, messages: [MessageProtocol]?) -> RoomProtocol {
		return Room(roomID: roomID, numberOfUsers: numberOfUsers, messages: messages)
	}
	
	init(roomID: NSUUID, numberOfUsers: Int?, messages: [MessageProtocol]?) {
		self.roomID = roomID
		self.numberOfUsers = numberOfUsers
		self.messages = messages ?? []
	}
	
	var roomID: NSUUID
	var numberOfUsers: Int?
	// Post-Condition: the messages are always sorted. First object is the latest message
	let messages: [MessageProtocol]
}

public class RoomProtocolFactory {
	private var registeredClass: RoomProtocol.Type?
	public static let sharedFactory = RoomProtocolFactory()
	
	private init() {
		
	}
	
	public func registerClass(`class`: RoomProtocol.Type) {
		self.registeredClass = `class`
	}
	
	public func instanciate(roomID roomID: NSUUID, numberOfUsers: Int?, messages: [MessageProtocol]?) -> RoomProtocol {
		let classType = self.registeredClass ?? Room.self
		return classType.newInstance(roomID: roomID, numberOfUsers: numberOfUsers, messages: messages)
	}
}
