//
//  MessageFactory.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/30/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

private class DefaultMessage: Message {
	class func newInstance(messageID messageID: NSUUID?, content: String, roomID: NSUUID, sender: User, dateSent: NSDate) -> Message {
		return DefaultMessage(messageID: messageID, content: content, roomID: roomID, sender: sender, dateSent: dateSent)
	}
	
	init(messageID: NSUUID?, content: String, roomID: NSUUID, sender: User, dateSent: NSDate) {
		self.messageID = messageID
		self.content = content
		self.roomID = roomID
		self.sender = sender
		self.dateSent = dateSent
	}
	
	let messageID: NSUUID?
	let content: String
	let sender: User
	let roomID: NSUUID
	let dateSent: NSDate
}

public class MessageFactory {
	private var registeredClass: Message.Type?
	public static let sharedFactory = MessageFactory()
	
	private init() {
		
	}
	
	public func registerClass(`class`: Message.Type) {
		self.registeredClass = `class`
	}
	
	public func instanciate(messageID messageID: NSUUID?, content: String, roomID: NSUUID, sender: User, dateSent: NSDate) -> Message {
		let classType = self.registeredClass ?? DefaultMessage.self
		return classType.newInstance(messageID: messageID, content: content, roomID: roomID, sender: sender, dateSent: dateSent)
	}
}
