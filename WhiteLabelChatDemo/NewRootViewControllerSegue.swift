//
//  NewRootViewControllerSegue.swift
//  WhiteLabelChatDemo
//
//  Created by Stephane Copin on 10/1/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit
import EthanolUIExtensions

class NewRootViewControllerSegue: UIStoryboardSegue {
	override func perform() {
		self.sourceViewController.view.window?.eth_transitionToNewRootViewController(self.destinationViewController, options: ETHAnimatedTransitionNewRootOptions(rawValue: 0), transitionOption: UIViewAnimationOptions.TransitionFlipFromLeft, completionHandler: nil)
	}
}
