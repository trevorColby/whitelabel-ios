//
//  SplashViewController.swift
//  WhiteLabelChatDemo
//
//  Created by Stephane Copin on 10/1/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {
	private let ShowChatViewControllerSegue = "ShowChatViewControllerSegue"
	private let ShowSignUpLoginViewControllerSegue = "ShowSignUpLoginViewControllerSegue"
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view.
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		if UserHelper.currentUser != nil {
			self.performSegueWithIdentifier(ShowChatViewControllerSegue, sender: self)
		} else {
			self.performSegueWithIdentifier(ShowSignUpLoginViewControllerSegue, sender: self)
		}
	}
}
