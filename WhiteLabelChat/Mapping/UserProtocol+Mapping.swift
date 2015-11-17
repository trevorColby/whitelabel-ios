//
//  User+Mapping.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

func mapUserFromJSON(json: JSON) throws -> User {
	guard let username = json["username"] as? String else {
		throw ErrorCode.IncompleteJSON
	}
	
	let user = UserFactory.sharedFactory.instanciate(userID: json["id"] as? String ?? json["uuid"] as? String, username: username, authToken: json["token"] as? String)
	if let userPhoto = json["userPhoto"] as? String {
		user.userPhoto = NSURL(string: userPhoto)
	}
	return user
}
