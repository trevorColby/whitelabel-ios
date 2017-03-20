//
//  MessageFactory.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/30/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

private class DefaultMessage: Message {
	class func newInstance(messageID: UUID, content: String, roomID: UUID, sender: User, dateSent: Date) -> Message {
		return DefaultMessage(messageID: messageID, content: content, roomID: roomID, sender: sender, dateSent: dateSent)
	}
	
	init(messageID: UUID, content: String, roomID: UUID, sender: User, dateSent: Date) {
		self.messageID = messageID
		self.content = content
		self.roomID = roomID
		self.sender = sender
		self.dateSent = dateSent
	}
	
	var messageID: UUID
	let content: String
	let sender: User
	let roomID: UUID
	var dateSent: Date
	var isBeingSent: Bool = false
}

open class MessageFactory {
	fileprivate var registeredClass: Message.Type?
	open static let sharedFactory = MessageFactory()
	
	fileprivate init() {
		
	}
	
	open func registerClass(_ class: Message.Type) {
		self.registeredClass = `class`
	}
	
	open func instanciate(messageID: UUID, content: String, roomID: UUID, sender: User, dateSent: Date) -> Message {
		let classType = self.registeredClass ?? DefaultMessage.self
		return classType.newInstance(messageID: messageID, content: content, roomID: roomID, sender: sender, dateSent: dateSent)
	}
}
