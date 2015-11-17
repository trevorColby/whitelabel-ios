//
//  Message.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/30/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

class Message: MessageProtocol {
	init(messageID: NSUUID?, content: String, roomID: NSUUID, sender: UserProtocol, dateSent: NSDate) {
		self.messageID = messageID
		self.content = content
		self.roomID = roomID
		self.sender = sender
		self.dateSent = dateSent
	}
	
	let messageID: NSUUID?
	let content: String
	let sender: UserProtocol
	let roomID: NSUUID
	let dateSent: NSDate
}
