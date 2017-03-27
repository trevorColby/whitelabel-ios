//
//  ISO8601DateFormatter.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 11/18/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit

class ISO8601DateFormatter {
	static fileprivate var iso8601DateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
		dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZZZZZ"
		return dateFormatter
	}()
	
	class func dateFromString(_ string: String) -> Date? {
		return self.iso8601DateFormatter.date(from: string)
	}
	
	class func stringFromDate(_ date: Date) -> String {
		return self.iso8601DateFormatter.string(from: date)
	}
}
