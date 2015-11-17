//
//  User+Authentication.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

public extension User {
	var isAuthenticated: Bool {
		return self.authToken != nil
	}
}
