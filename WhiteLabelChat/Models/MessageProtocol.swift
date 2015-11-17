//
//  MessageProtocol.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 11/17/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

public protocol MessageProtocol: class, Mappable {
	static func newInstance(messageID messageID: NSUUID?, content: String, roomID: NSUUID, sender: UserProtocol, dateSent: NSDate) -> MessageProtocol
	
	var messageID: NSUUID? { get }
	var content: String { get }
	var sender: UserProtocol { get }
	var roomID: NSUUID { get }
	var dateSent: NSDate { get }
}
