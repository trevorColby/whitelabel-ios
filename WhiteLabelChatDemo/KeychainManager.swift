//
//  KeychainManager.swift
//  WhiteLabelChatDemo
//
//  Created by Stephane Copin on 10/1/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import KeychainAccess

class KeychainManager: NSObject {
	private var keychain: Keychain
	
	class var sharedManager: KeychainManager {
		struct Static {
			static let manager = KeychainManager()
		}
		return Static.manager
	}
	
	override init() {
		self.keychain = Keychain(service: NSBundle.mainBundle().bundleIdentifier!)
	}
	
	subscript(key: String) -> NSData? {
		get {
			do {
				return try self.keychain.getData(key)
			} catch {
				return nil
			}
		}
		set {
			if let newValue = newValue {
				do {
					try self.keychain.set(newValue, key: key)
				} catch {
					print("Error while setting keychain key \(key) to value \(newValue)")
				}
			} else {
				self.keychain[key] = nil
			}
		}
	}
}
