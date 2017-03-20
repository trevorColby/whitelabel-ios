//
//  Message+Mapping.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/30/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

@discardableResult
func mapMessageFromJSON(_ json: JSON, withExistingMessage existingMessage: Message? = nil) throws -> Message {
	guard let id = json["uuid"] as? String, let uuid = UUID(uuidString: id),
		let content = json["message"] as? String,
		let roomID = json["room"] as? String, let roomUUID = UUID(uuidString: roomID),
		let sent = json["sent"] as? String,
		let dateSent = ISO8601DateFormatter.dateFromString(sent) else
	{
			throw ErrorCode.incompleteJSON
	}
	let sender = try mapUserFromJSON(json)
	
	if let existingMessage = existingMessage, existingMessage.roomID == roomUUID && existingMessage.content == content && existingMessage.sender.userID == sender.userID && existingMessage.sender.username == sender.username {
		existingMessage.messageID = uuid
		existingMessage.dateSent = dateSent
		return existingMessage
	}
	
	let message = MessageFactory.sharedFactory.instanciate(messageID: uuid, content: content, roomID: roomUUID, sender: sender, dateSent: dateSent)
	if existingMessage != nil {
		LogManager.sharedManager.log(.warning, message: "Was given existing message \(existingMessage) which didn't match with the received response \(json), so created new message \(message)")
	}
	return message
}
