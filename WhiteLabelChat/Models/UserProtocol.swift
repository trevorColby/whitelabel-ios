//
//  UserProtocol.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 11/17/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

public protocol UserProtocol: class, Mappable {
	static func newInstance(userID userID: String?, username: String, authToken: String?) -> UserProtocol
	
	var userID: String? { get }
	var username: String { get }
	var userPhoto: NSURL? { get set }
	var authToken: String? { get }
}
