//
//  Message.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 11/17/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

public protocol Message: class {
	static func newInstance(messageID: UUID, content: String, roomID: UUID, sender: User, dateSent: Date) -> Message
	
	var messageID: UUID { get set }
	var content: String { get }
	var sender: User { get }
	var roomID: UUID { get }
	var dateSent: Date { get set }
	var isBeingSent: Bool { get set }
}
