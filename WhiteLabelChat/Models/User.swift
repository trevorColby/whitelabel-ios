//
//  User.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit

public class User: UserProtocol {
	init(userID: String?, username: String) {
		self.userID = userID
		self.username = username
	}
	
	public let userID: String?
	public let username: String
	public var userPhoto: NSURL?
	public internal(set) var authToken: String?
}
