//
//  Message.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/30/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

public class Message: MessageProtocol {
	init(messageID: NSUUID?, content: String, roomID: NSUUID, sender: UserProtocol, dateSent: NSDate) {
		self.messageID = messageID
		self.content = content
		self.roomID = roomID
		self.sender = sender
		self.dateSent = dateSent
	}
	
	public let messageID: NSUUID?
	public let content: String
	public let sender: UserProtocol
	public let roomID: NSUUID
	public let dateSent: NSDate
}
