//
//  ISO8601DateFormatter.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 11/18/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit

class ISO8601DateFormatter {
	static private var iso8601DateFormatter: NSDateFormatter = {
		let dateFormatter = NSDateFormatter()
		dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
		dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZZZZZ"
		return dateFormatter
	}()
	
	class func dateFromString(string: String) -> NSDate? {
		return self.iso8601DateFormatter.dateFromString(string)
	}
	
	class func stringFromDate(date: NSDate) -> String {
		return self.iso8601DateFormatter.stringFromDate(date)
	}
}
