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
		Configuration.defaultBaseURL = NSURL(string: "https://stephane.pagekite.me/")
		
		let chatController = ChatController()
		User.registerWithUsername("test1", password: "fueled") { (user, error) in
			User.loginWithUsername("test1", password: "fueled") { (user, error) in
				if let user = user {
					print(user)
					chatController.connectWithUser(user) { (error) -> () in
						try! chatController.joinRoom(roomUUID: NSUUID(UUIDString: "6CE97FFF-224D-43D5-8BFF-8AE62204BA6C")!, userPhoto: "asd") { (error) -> () in
							print("Join room: \(error)")
							try! chatController.sendMessage("lol", roomUUID: NSUUID(UUIDString: "6CE97FFF-224D-43D5-8BFF-8AE62204BA6C")!, userPhoto: "asd") { (error) -> () in
								print("Send message: \(error)")
							}
						}
					}
				}
			}
		}
		
		return true
	}
}
