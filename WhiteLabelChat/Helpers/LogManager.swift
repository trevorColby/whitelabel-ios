//
//  LogManager.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 11/18/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit

public class LogManager {
	public enum Level: Int {
		case Disabled = 0
		case Error = 1
		case Warning = 2
		case Debug = 3
		case All = 100
	}
	
	public typealias LogFunction = (level: Level, message: String, file: String, function: String, line: UInt) -> Void
	
	public static let sharedManager = LogManager()

	private init() {
		
	}
	
	private let defaultLogFunction: LogFunction = { (level, message, _, _, _) in
		return NSLog(message)
	}
	
	private var logFunctionStorage: LogFunction?
	// Can never be nil, but setting it to nil will reset it the default log function
	public var logFunction: LogFunction! {
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
	
	public var logLevel: Level = .Disabled
	
	internal func log(level: Level, message: String, file: String = #file, function: String = __FUNCTION__, line: UInt = __LINE__) {
		if level != .Disabled && level.rawValue <= self.logLevel.rawValue {
			self.logFunction(level: level, message: message, file: file, function: function, line: line)
		}
	}
}
