//
//  Room+Mapping.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/30/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

public extension Room {
	public class func mapFromJSON(json: JSON) throws -> Room {
		guard let id = json["room"] as? String, let uuid = NSUUID(UUIDString: id), let numberOfUsers = json["numUsers"] as? Int else {
			throw ErrorCode.IncompleteJSON
		}
		
		let room = Room(roomID: uuid, numberOfUsers: numberOfUsers)
		if let messagesJSON = json["messages"] as? [JSON] {
			var messages: [Message] = []
			for messageJSON in messagesJSON {
				if let message = try? Message.mapFromJSON(messageJSON) {
					messages.append(message)
				}
			}
			room.messages = messages
		}
		return room
	}
}
