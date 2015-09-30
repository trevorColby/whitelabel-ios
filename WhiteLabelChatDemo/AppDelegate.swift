//
//  AppDelegate.swift
//  WhiteLabelChatDemo
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit
import WhiteLabelChat

extension UIDevice {
	static var modelName: String {
		var systemInfo = utsname()
		uname(&systemInfo)
		let machineMirror = Mirror(reflecting: systemInfo.machine)
		let identifier = machineMirror.children.reduce("") { identifier, element in
			guard let value = element.value as? Int8 where value != 0 else { return identifier }
			return identifier + String(UnicodeScalar(UInt8(value)))
		}
		
		switch identifier {
		case "iPod5,1":                                 return "iPod Touch 5"
		case "iPod7,1":                                 return "iPod Touch 6"
		case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
		case "iPhone4,1":                               return "iPhone 4s"
		case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
		case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
		case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
		case "iPhone7,2":                               return "iPhone 6"
		case "iPhone7,1":                               return "iPhone 6 Plus"
		case "iPhone8,1":                               return "iPhone 6s"
		case "iPhone8,2":                               return "iPhone 6s Plus"
		case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
		case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
		case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
		case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
		case "iPad5,1", "iPad5,3", "iPad5,4":           return "iPad Air 2"
		case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
		case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
		case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
		case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
		case "i386", "x86_64":                          return "Simulator"
		default:                                        return identifier
		}
	}
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		Configuration.defaultBaseURL = NSURL(string: "http://172.16.29.225:3000/")
		
		let roomUUID = NSUUID(UUIDString: "6CE97FFF-224D-43D5-8BFF-8AE62204BA6C")!
		let username: String = UIDevice.modelName.lowercaseString.stringByReplacingOccurrencesOfString(" ", withString: "")
		
		let chatController = ChatController()
		User.registerWithUsername(username, password: "fueled") { (user, error) in
			print("register: \(user) \(error)")
			User.loginWithUsername(username, password: "fueled") { (user, error) in
				print("login: \(user) \(error)")
				if let user = user {
					chatController.connectWithUser(user) { (error) -> () in
						try! chatController.joinRoom(roomUUID: roomUUID, userPhoto: "asd") { (room, error) -> () in
							print("Join room: \(room) \(error)")
							try! chatController.sendMessage("lol", roomUUID: roomUUID, userPhoto: "asd") { (message, error) -> () in
								print("Send message: \(message) \(error)")
							}
						}
					}
				}
			}
		}
		
		return true
	}
}
