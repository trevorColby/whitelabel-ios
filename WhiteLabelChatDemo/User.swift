//
//  User.swift
//  WhiteLabelChatDemo
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit
import WhiteLabelChat

enum MappingError: ErrorType {
	case IncompleteJSON
}

public class User: UserProtocol {
	init(userID: String?, username: String) {
		self.userID = userID
		self.username = username
	}
	
	public let userID: String?
	public let username: String
	public var userPhoto: NSURL?
	public var authToken: String?
	
	class func mapFromJSON(json: JSON) throws -> User {
		guard let username = json["username"] as? String else {
			throw MappingError.IncompleteJSON
		}
		
		let user = User(userID: json["id"] as? String, username: username)
		user.authToken = json["token"] as? String
		if let userPhoto = json["userPhoto"] as? String {
			user.userPhoto = NSURL(string: userPhoto)
		}
		return user
	}
}
