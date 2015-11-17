//
//  RoomProtocol.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 11/17/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

public protocol RoomProtocol: class, Mappable {
	static func newInstance(roomID roomID: NSUUID, numberOfUsers: Int?, messages: [MessageProtocol]?) -> RoomProtocol
	
	var roomID: NSUUID { get }
	var numberOfUsers: Int? { get }
	// Post-Condition: the messages are always sorted. First object is the latest message
	var messages: [MessageProtocol] { get }
}
