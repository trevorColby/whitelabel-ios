//
//  Room.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 11/17/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

public protocol Room: class {
	static func newInstance(roomID: UUID, numberOfUsers: Int?, messages: [Message]?) -> Room
	
	var roomID: UUID { get }
	var numberOfUsers: Int? { get }
	var arrayOfMessages: [Message] { get }
}
