//
//  Message.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/30/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

public class Message: NSObject {
	init(messageID: NSUUID?, roomID: NSUUID, sender: User, dateSent: NSDate) {
		self.messageID = messageID
		self.roomID = roomID
		self.sender = sender
		self.dateSent = dateSent
	}
	
	public let messageID: NSUUID?
	public let sender: User
	public let roomID: NSUUID
	public let dateSent: NSDate
}
