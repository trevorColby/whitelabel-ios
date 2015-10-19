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
	private let ShowChatViewControllerSegue = "ShowChatViewControllerSegue"
	
	@IBOutlet var usernameTextField: UITextField!
	@IBOutlet var passwordTextField: UITextField!
	
	@IBAction func signUpButtonTapped(sender: AnyObject) {
		let username = self.usernameTextField.text ?? ""
		User.registerWithUsername(username, password: self.passwordTextField.text ?? "") { (user, error) in
			if let error = error {
				print("Failed to sign up with username \(username): \(error)")
			} else if let user = user {
				UserHelper.persistUser(user)
				print("Successfully signed up with username \(username)")
				self.performSegueWithIdentifier(self.ShowChatViewControllerSegue, sender: self)
			}
		}
	}
	
	@IBAction func loginButtonTapped(sender: AnyObject) {
		let username = self.usernameTextField.text ?? ""
		User.loginWithUsername(username, password: self.passwordTextField.text ?? "") { (user, error) in
			if let error = error {
				print("Failed to login with username \(username): \(error)")
			} else if let user = user {
				UserHelper.persistUser(user)
				print("Successfully logged in with username \(username)")
				
				self.performSegueWithIdentifier(self.ShowChatViewControllerSegue, sender: self)
			}
		}
	}
}
