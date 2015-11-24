//
//  Message+Mapping.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/30/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

func mapMessageFromJSON(json: JSON, withExistingMessage existingMessage: Message? = nil) throws -> Message {
	guard let id = json["uuid"] as? String, let uuid = NSUUID(UUIDString: id),
		let content = json["message"] as? String,
		let roomID = json["room"] as? String, let roomUUID = NSUUID(UUIDString: roomID),
		let sent = json["sent"] as? String,
		let dateSent = ISO8601DateFormatter.dateFromString(sent) else
	{
			throw ErrorCode.IncompleteJSON
	}
	let sender = try mapUserFromJSON(json)
	
	if let existingMessage = existingMessage where existingMessage.roomID == roomUUID && existingMessage.content == content && existingMessage.sender.userID == sender.userID && existingMessage.sender.username == sender.username {
		existingMessage.messageID = uuid
		existingMessage.dateSent = dateSent
		return existingMessage
	}
	
	let message = MessageFactory.sharedFactory.instanciate(messageID: uuid, content: content, roomID: roomUUID, sender: sender, dateSent: dateSent)
	if existingMessage != nil {
		LogManager.sharedManager.log(.Warning, message: "Was given existing message \(existingMessage) which didn't match with the received response \(json), so created new message \(message)")
	}
	return message
}
