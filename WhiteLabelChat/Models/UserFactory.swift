//
//  UserFactory.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit

private class DefaultUser: User {
	class func newInstance(userID userID: String, username: String, authToken: String?) -> User {
		return DefaultUser(userID: userID, username: username, authToken: authToken)
	}
	
	init(userID: String, username: String, authToken: String?) {
		self.userID = userID
		self.username = username
		self.authToken = authToken
	}
	
	let userID: String
	let username: String
	var userPhoto: NSURL?
	let authToken: String?
}

public class UserFactory {
	private var registeredClass: User.Type?
	public static let sharedFactory = UserFactory()
	
	private init() {
		
	}
	
	public func registerClass(`class`: User.Type) {
		self.registeredClass = `class`
	}
	
	public func instanciate(userID userID: String, username: String, authToken: String?) -> User {
		let classType = self.registeredClass ?? DefaultUser.self
		return classType.newInstance(userID: userID, username: username, authToken: authToken)
	}
}
