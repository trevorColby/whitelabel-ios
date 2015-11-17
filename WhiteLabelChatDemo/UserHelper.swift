//
//  UserHelper.swift
//  WhiteLabelChatDemo
//
//  Created by Stephane Copin on 10/1/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit
import WhiteLabelChat

private var currentUserInstance: UserProtocol?

class UserHelper {
	private static let CachedUserKey = "CachedUserKey"
	
	private class var cachedUser: UserProtocol? {
		get {
			if let data = KeychainManager.sharedManager[CachedUserKey] {
				if let json = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? JSON {
					let user = UserProtocolFactory.sharedFactory.instanciate(userID: json["id"] as? String, username: json["username"] as! String, authToken: json["token"] as? String)
					if let userPhoto = json["userPhoto"] as? String {
						user.userPhoto = NSURL(string: userPhoto)
					}
					return user
				}
			}
			return nil
		}
		set(newValue) {
			if let user = newValue {
				var dictionary = [
					"username": user.username,
				]
				if let id = user.userID {
					dictionary["id"] = id
				}
				if let authToken = user.authToken {
					dictionary["token"] = authToken
				}
				if let userPhoto = user.userPhoto {
					dictionary["userPhoto"] = userPhoto.absoluteString
				}
				let data = NSKeyedArchiver.archivedDataWithRootObject(dictionary)
				KeychainManager.sharedManager[CachedUserKey] = data
			} else {
				KeychainManager.sharedManager[CachedUserKey] = nil
			}
		}
	}
	
	class var currentUser: UserProtocol? {
		get {
			if let cachedUser = cachedUser {
				currentUserInstance = cachedUser
			}
			return currentUserInstance
		}
	}
	
	class func persistUser(user: UserProtocol) {
		cachedUser = user
	}
	
	class func logoutUser() {
		cachedUser = nil
		currentUserInstance = nil
	}
}
