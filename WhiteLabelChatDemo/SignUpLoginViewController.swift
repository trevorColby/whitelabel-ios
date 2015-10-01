//
//  SignUpLoginViewController.swift
//  WhiteLabelChatDemo
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit
import WhiteLabelChat

class SignUpLoginViewController: UIViewController {
	@IBOutlet var usernameTextField: UITextField!
	@IBOutlet var passwordTextField: UITextField!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}
	
	@IBAction func signUpButtonTapped(sender: AnyObject) {
		let username = self.usernameTextField.text ?? ""
		User.registerWithUsername(username, password: "fueled") { (user, error) in
			if let error = error {
				print("Failed to sign up with username \(username): \(error)")
			} else {
				print("Successfully signed up with username \(username)")
			}
		}
	}
	
	@IBAction func loginButtonTapped(sender: AnyObject) {
		let username = self.usernameTextField.text ?? ""
		User.loginWithUsername(username, password: "fueled") { (user, error) in
			if let error = error {
				print("Failed to login with username \(username): \(error)")
			} else {
				print("Successfully logged in with username \(username)")
			}
		}
	}
}
