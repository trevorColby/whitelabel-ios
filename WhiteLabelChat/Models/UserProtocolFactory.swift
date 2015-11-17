//
//  UserProtocolFactory.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit

private class User: UserProtocol {
	class func newInstance(userID userID: String?, username: String, authToken: String?) -> UserProtocol {
		return User(userID: userID, username: username, authToken: authToken)
	}
	
	init(userID: String?, username: String, authToken: String?) {
		self.userID = userID
		self.username = username
		self.authToken = authToken
	}
	
	let userID: String?
	let username: String
	var userPhoto: NSURL?
	let authToken: String?
}

public class UserProtocolFactory {
	private var registeredClass: UserProtocol.Type?
	public static let sharedFactory = UserProtocolFactory()
	
	private init() {
		
	}
	
	public func registerClass(`class`: UserProtocol.Type) {
		self.registeredClass = `class`
	}
	
	public func instanciate(userID userID: String?, username: String, authToken: String?) -> UserProtocol {
		let classType = self.registeredClass ?? User.self
		return classType.newInstance(userID: userID, username: username, authToken: authToken)
	}
}
