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
}
