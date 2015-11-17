//
//  Room.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 11/17/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

public protocol Room: class {
	static func newInstance(roomID roomID: NSUUID, numberOfUsers: Int?, messages: [Message]?) -> Room
	
	var roomID: NSUUID { get }
	var numberOfUsers: Int? { get }
	var arrayOfMessages: [Message] { get }
}
