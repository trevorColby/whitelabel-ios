//
//  ChatViewController.swift
//  WhiteLabelChatDemo
//
//  Created by Stephane Copin on 10/1/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit
import WhiteLabelChat

class ChatViewController: UIViewController {
	private var currentUser: User!
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		assert(UserHelper.currentUser != nil, "This view cannot be displayed if the current user is nil")
		
		self.currentUser = UserHelper.currentUser
	}
}
