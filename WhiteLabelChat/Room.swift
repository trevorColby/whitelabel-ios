//
//  Room.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/30/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

public class Room: NSObject {
	init(roomID: NSUUID, numberOfUsers: Int?) {
		self.roomID = roomID
		self.numberOfUsers = numberOfUsers
	}
	
	public var roomID: NSUUID
	internal(set) public var numberOfUsers: Int?
	// Post-Condition: messages is always sorted. First object is the latest message
	internal(set) public var messages: [Message] = []
	
	public func addMessage(message: Message) -> Int {
		return self.addMessages([message]).firstIndex
	}
	
	public func addMessages(var messages: [Message]) -> NSIndexSet {
		messages.sortInPlace { (message1, message2) -> Bool in
			return message2.dateSent.timeIntervalSinceDate(message1.dateSent) > 0
		}
		let array = self.messages as NSArray
		let indexSet = NSMutableIndexSet()
		for message in messages {
			let sortedIndex = array.indexOfObject(message, inSortedRange: NSMakeRange(0, self.messages.count), options: .InsertionIndex) { (messageObject1, messageObject2) -> NSComparisonResult in
				guard let message1 = messageObject1 as? Message else {
					if messageObject2 is Message {
						return .OrderedDescending
					}
					return .OrderedSame
				}
				guard let message2 = messageObject2 as? Message else {
					return .OrderedAscending
				}
				
				return message2.dateSent.compare(message1.dateSent)
			}
			indexSet.addIndex(sortedIndex)
			self.messages.insert(message, atIndex: sortedIndex)
		}
		return indexSet
	}
}
