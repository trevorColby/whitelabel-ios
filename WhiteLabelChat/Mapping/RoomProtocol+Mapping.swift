//
//  Room+Mapping.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/30/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

func mapRoomFromJSON(_ json: JSON) throws -> Room {
	guard let id = json["room"] as? String, let uuid = UUID(uuidString: id) else {
		throw ErrorCode.incompleteJSON
	}
	
	var messages: [Message]!
	if let messagesJSON = json["messages"] as? [JSON] {
		messages = []
		for messageJSON in messagesJSON {
			if let message = try? mapMessageFromJSON(messageJSON) {
				messages.append(message)
			}
		}
	}
	let room = RoomFactory.sharedFactory.instanciate(roomID: uuid, numberOfUsers: json["numUsers"] as? Int, messages: messages)
	return room
}
