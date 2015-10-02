//
//  User+Mapping.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

public extension User {
	public class func mapFromJSON(json: JSON) throws -> User {
		guard let username = json["username"] as? String else {
			throw ErrorCode.IncompleteJSON
		}
		
		let user = User(userID: json["id"] as? String, username: username)
		user.authToken = json["token"] as? String
		if let userPhoto = json["userPhoto"] as? String {
			user.userPhoto = NSURL(string: userPhoto)
		}
		return user
	}
	
	public func toJSON() -> JSON {
		var result = [
			"username": self.username,
		]
		if let id = self.userID {
			result["id"] = id
		}
		if let authToken = self.authToken {
			result["token"] = authToken
		}
		if let userPhoto = self.userPhoto {
			result["userPhoto"] = userPhoto.absoluteString
		}
		return result
	}
}
