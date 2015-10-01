//
//  UserHelper.swift
//  WhiteLabelChatDemo
//
//  Created by Stephane Copin on 10/1/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit
import WhiteLabelChat

private var currentUserInstance: User?

class UserHelper {
	private static let CachedUserKey = "CachedUserKey"
	
	private class var cachedUser: User? {
		get {
		if let data = KeychainManager.sharedManager[CachedUserKey] {
		if let json = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? JSON {
		return (try? User.mapFromJSON(json)) ?? nil
		}
		}
		return nil
		}
		set(newValue) {
			if let user = newValue {
				let dictionary = user.toJSON()
				let data = NSKeyedArchiver.archivedDataWithRootObject(dictionary)
				KeychainManager.sharedManager[CachedUserKey] = data
			} else {
				KeychainManager.sharedManager[CachedUserKey] = nil
			}
		}
	}
	
	// This is always nil on application startup. In order to login, any of the public loginXxxx method must be called (Login is instantaneous when internet is unreachable)
	class var currentUser: User? {
		get {
			if let cachedUser = cachedUser {
				currentUserInstance = cachedUser
			}
			return currentUserInstance
		}
	}
	
	class func persistUser(user: User) {
		cachedUser = user
	}
}
