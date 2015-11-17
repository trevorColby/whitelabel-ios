//
//  User.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit

class User: UserProtocol {
	init(userID: String?, username: String) {
		self.userID = userID
		self.username = username
	}
	
	let userID: String?
	let username: String
	var userPhoto: NSURL?
	var authToken: String?
}
