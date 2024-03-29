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
					let user = UserFactory.sharedFactory.instanciate(userID: json["id"] as! String, username: json["username"] as! String, authToken: json["token"] as? String)
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
					"id": user.userID,
					"username": user.username,
				]
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
	
	class func logoutUser() {
		cachedUser = nil
		currentUserInstance = nil
	}
}
