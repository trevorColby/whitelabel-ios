//
//  MessageProtocolFactory.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/30/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

private class Message: MessageProtocol {
	class func newInstance(messageID messageID: NSUUID?, content: String, roomID: NSUUID, sender: UserProtocol, dateSent: NSDate) -> MessageProtocol {
		return Message(messageID: messageID, content: content, roomID: roomID, sender: sender, dateSent: dateSent)
	}
	
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

public class MessageProtocolFactory {
	private var registeredClass: MessageProtocol.Type?
	public static let sharedFactory = MessageProtocolFactory()
	
	private init() {
		
	}
	
	public func registerClass(`class`: MessageProtocol.Type) {
		self.registeredClass = `class`
	}
	
	public func instanciate(messageID messageID: NSUUID?, content: String, roomID: NSUUID, sender: UserProtocol, dateSent: NSDate) -> MessageProtocol {
		let classType = self.registeredClass ?? Message.self
		return classType.newInstance(messageID: messageID, content: content, roomID: roomID, sender: sender, dateSent: dateSent)
	}
}
