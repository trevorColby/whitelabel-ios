//
//  User.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 11/17/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

public protocol User: class {
	static func newInstance(userID: String, username: String, authToken: String?) -> User
	
	var userID: String { get }
	var username: String { get }
	var userPhoto: URL? { get set }
	var authToken: String? { get }
}
