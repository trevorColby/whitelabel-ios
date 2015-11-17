//
//  RoomProtocol+Mapping.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/30/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

func mapRoomFromJSON(json: JSON) throws -> RoomProtocol {
	guard let id = json["room"] as? String, let uuid = NSUUID(UUIDString: id) else {
		throw ErrorCode.IncompleteJSON
	}
	
	var messages: [MessageProtocol]!
	if let messagesJSON = json["messages"] as? [JSON] {
		messages = []
		for messageJSON in messagesJSON {
			if let message = try? mapMessageFromJSON(messageJSON) {
				messages.append(message)
			}
		}
	}
	let room = RoomProtocolFactory.sharedFactory.instanciate(roomID: uuid, numberOfUsers: json["numUsers"] as? Int, messages: messages)
	return room
}
