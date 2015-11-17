//
//  Message+Mapping.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/30/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

extension Message {
	class func mapFromJSON(var json: JSON) throws -> Message {
		guard let id = json["uuid"] as? String, let uuid = NSUUID(UUIDString: id),
			let content = json["message"] as? String,
			let roomID = json["room"] as? String, let roomUUID = NSUUID(UUIDString: roomID),
			let _ = json["sent"] as? String else {
			throw ErrorCode.IncompleteJSON
		}
		let sender = try User.mapFromJSON(json)
		
		return Message(messageID: uuid, content: content, roomID: roomUUID, sender: sender, dateSent: NSDate())
	}
}
