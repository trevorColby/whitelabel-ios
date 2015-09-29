//
//  User+Login.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

public extension User {
	public class func registerWithUsername(username: String, password: String, completionHandler: ((user: User?, error: ErrorType?) -> ())? = nil) {
		self.handleSignUpLogin(isSignUp: true, username: username, password: password, completionHandler: completionHandler)
		
	}
	
	public class func loginWithUsername(username: String, password: String, completionHandler: ((user: User?, error: ErrorType?) -> ())? = nil) {
		self.handleSignUpLogin(isSignUp: false, username: username, password: password, completionHandler: completionHandler)
	}
	
	private class func handleSignUpLogin(isSignUp signUp: Bool, username: String, password: String, completionHandler: ((user: User?, error: ErrorType?) -> ())? = nil) {
		WhiteLabelHTTPClient.sharedClient.sendRequest(.POST, path: signUp ? "sign-up" : "auth/", parameters: ["username": username, "password": password]) { (data, error) -> () in
			if let error = error {
				completionHandler?(user: nil, error: error)
				return
			}
			
			guard let data = data else {
				completionHandler?(user: nil, error: nil)
				return
			}
			
			let user: User
			do {
				guard let token = data["token"] as? String else {
					throw ErrorCode.IncompleteJSON
				}
				
				user = try User.mapFromJSON(data)
				user.authToken = token
			} catch {
				completionHandler?(user: nil, error: error)
				return
			}
			
			completionHandler?(user: user, error: nil)
		}
	}
	
	var isAuthenticated: Bool {
		return self.authToken != nil
	}
}
