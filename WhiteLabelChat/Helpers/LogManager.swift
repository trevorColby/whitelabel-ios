//
//  LogManager.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 11/18/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit

open class LogManager {
	public enum Level: Int {
		case disabled = 0
		case error = 1
		case warning = 2
		case debug = 3
		case all = 100
	}
	
	public typealias LogFunction = (_ level: Level, _ message: String, _ file: String, _ function: String, _ line: UInt) -> Void
	
    public static let sharedManager = LogManager()

	fileprivate init() {
		
	}
	
	fileprivate let defaultLogFunction: LogFunction = { (level, message, _, _, _) in
		return NSLog(message)
	}
	
	fileprivate var logFunctionStorage: LogFunction?
	// Can never be nil, but setting it to nil will reset it the default log function
	open var logFunction: LogFunction! {
		get {
			if let logFunction = self.logFunctionStorage {
				return logFunction
			}
			return self.defaultLogFunction
		}
		set {
			self.logFunctionStorage = newValue
		}
	}
	
	open var logLevel: Level = .disabled
	
	internal func log(_ level: Level, message: String, file: String = #file, function: String = #function, line: UInt = #line) {
		if level != .disabled && level.rawValue <= self.logLevel.rawValue {
			self.logFunction(level, message, file, function, line)
		}
	}
}
