//
//  AppDelegate.swift
//  WhiteLabelChatDemo
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit
import WhiteLabelChat

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		Configuration.defaultBaseURL = NSURL(string: "http://localhost:3000/")
			
		User.loginWithUsername("test1", password: "fueled") { (user, error) in
			print("\(user?.isAuthenticated)")
		}
		
		return true
	}
}
