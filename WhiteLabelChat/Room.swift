//
//  Room.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/30/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

public class Room: NSObject {
	init(roomID: NSUUID, numberOfUsers: Int) {
		self.roomID = roomID
		self.numberOfUsers = numberOfUsers
	}
	
	public var roomID: NSUUID
	internal(set) public var numberOfUsers: Int
	internal(set) public var messages: [Message] = []
}
