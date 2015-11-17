//
//  Room.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/30/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

public class Room: RoomProtocol {
	init(roomID: NSUUID, numberOfUsers: Int?) {
		self.roomID = roomID
		self.numberOfUsers = numberOfUsers
	}
	
	public internal(set) var roomID: NSUUID
	public internal(set) var numberOfUsers: Int?
	// Post-Condition: the messages are always sorted. First object is the latest message
	public internal(set) var messages: [MessageProtocol] = []
	
	public func addMessage(message: MessageProtocol) -> Int {
		return self.addMessages([message]).first ?? 0
	}
	
	public func addMessages(messages: [MessageProtocol]) -> [Int] {
		var indexes: [Int] = []
		for message in messages {
			let sortedIndex = (self.messages.map { $0.dateSent } as NSArray).indexOfObject(message.dateSent, inSortedRange: NSMakeRange(0, self.messages.count), options: NSBinarySearchingOptions.InsertionIndex) { (dateObject1, dateObject2) -> NSComparisonResult in
				guard let date1 = dateObject1 as? NSDate else {
					if dateObject2 is NSDate {
						return .OrderedDescending
					}
					return .OrderedSame
				}
				guard let date2 = dateObject2 as? NSDate else {
					return .OrderedAscending
				}
				
				return date2.compare(date1)
			}
			indexes = indexes.map { ($0 >= sortedIndex) ? ($0 + 1) : $0 }
			indexes.append(sortedIndex)
			self.messages.insert(message, atIndex: sortedIndex)
		}
		return indexes
	}
}
