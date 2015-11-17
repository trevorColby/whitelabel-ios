//
//  Message.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 11/17/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

public protocol Message: class {
	static func newInstance(messageID messageID: NSUUID?, content: String, roomID: NSUUID, sender: User, dateSent: NSDate) -> Message
	
	var messageID: NSUUID? { get }
	var content: String { get }
	var sender: User { get }
	var roomID: NSUUID { get }
	var dateSent: NSDate { get }
}
