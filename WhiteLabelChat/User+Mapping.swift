//
//  User+Mapping.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

extension User {
	class func mapFromJSON(json: JSON) throws -> User {
		guard let id = json["id"] as? String, let username = json["username"] as? String else {
			throw ErrorCode.IncompleteJSON
		}
		
		let user = User(userID: id, username: username)
		user.authToken = json["token"] as? String
		return user
	}
	
	func toJSON() -> JSON {
		var result = [
			"id": self.userID,
			"username": self.username,
		]
		if let authToken = self.authToken {
			result["token"] = authToken
		}
		return result
	}
}
