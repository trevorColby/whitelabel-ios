//
//  UserFactory.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit

private class DefaultUser: User {
	class func newInstance(userID: String, username: String, authToken: String?) -> User {
		return DefaultUser(userID: userID, username: username, authToken: authToken)
	}
	
	init(userID: String, username: String, authToken: String?) {
		self.userID = userID
		self.username = username
		self.authToken = authToken
	}
	
	let userID: String
	let username: String
	var userPhoto: URL?
	let authToken: String?
}

open class UserFactory {
	fileprivate var registeredClass: User.Type?
	open static let sharedFactory = UserFactory()
	
	fileprivate init() {
		
	}
	
	open func registerClass(_ class: User.Type) {
		self.registeredClass = `class`
	}
	
	open func instanciate(userID: String, username: String, authToken: String?) -> User {
		let classType = self.registeredClass ?? DefaultUser.self
		return classType.newInstance(userID: userID, username: username, authToken: authToken)
	}
}
