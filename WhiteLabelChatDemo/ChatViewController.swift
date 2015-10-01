//
//  ChatViewController.swift
//  WhiteLabelChatDemo
//
//  Created by Stephane Copin on 10/1/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit
import WhiteLabelChat

private let UIAnimationOptionsFromCurve = {(curve: UIViewAnimationCurve) -> UIViewAnimationOptions in
	switch (curve) {
	case .EaseInOut:
		return .CurveEaseInOut
	case .EaseIn:
		return .CurveEaseIn
	case .EaseOut:
		return .CurveEaseOut
	case .Linear:
		return .CurveLinear
	}
}

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
	private let ChatMessageTableViewCellReuseIdentifier = "ChatMessageTableViewCellReuseIdentifier"
	private let RoomUUID = NSUUID(UUIDString: "6CE97FFF-224D-43D5-8BFF-8AE62204BA6C")!
	
	private var currentUser: User!
	private let chatController = ChatController()
	private var room: Room?
	
	@IBOutlet var tableView: UITableView!
	@IBOutlet var messageTextField: UITextField!
	@IBOutlet var messageTextFieldBottomConstraint: NSLayoutConstraint!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "chatControllerReceivedNewMessageNotificationHandler:", name: ChatControllerReceivedNewMessageNotification, object: self.chatController)
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillChangeFrameNotificationHandler:", name: UIKeyboardWillChangeFrameNotification, object: nil)
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		assert(UserHelper.currentUser != nil, "This view cannot be displayed if the current user is nil")
		
		self.currentUser = UserHelper.currentUser
		self.currentUser.userPhoto = NSURL(string: "http://lorempixel.com/100/100/cats/1/\(self.currentUser.username)/")
		self.navigationController?.setNavigationBarHidden(false, animated: true)
		self.navigationController?.navigationItem.hidesBackButton = true
		self.navigationController?.hidesBarsOnSwipe = true
		
		self.chatController.connectWithUser(self.currentUser) { (error) -> () in
			if let error = error {
				print("Couldn't connect to chat: \(error)")
				return
			}
			print("Connected to chat")
			do {
				try self.chatController.joinRoom(roomUUID: self.RoomUUID) { (room, error) in
					if let error = error {
						print("Couldn't join room \(self.RoomUUID.UUIDString) to chat: \(error)")
						return
					}
					if let room = room {
						print("Joined room \(room.roomID.UUIDString)")
						self.room = room
						self.reloadMessages()
					}
				}
			} catch {
				print("Couldn't join room \(self.RoomUUID.UUIDString) to chat: \(error)")
			}
		}
	}
	
	@IBAction func sendMessageButtonTapped(sender: AnyObject) {
		if let room = self.room {
			do {
				try self.chatController.sendMessage(self.messageTextField.text ?? "", roomUUID: room.roomID)
			} catch {
				print("Couldn't send message: \(error)")
			}
		}
	}
	
	private func reloadMessages() {
		self.tableView.reloadData()
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.room?.messages.count ?? 0
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(ChatMessageTableViewCellReuseIdentifier, forIndexPath: indexPath) as! ChatMessageTableViewCell
		if let room = room {
			cell.usernameLabel.text = room.messages[indexPath.row].sender.username
			cell.messageLabel.text = room.messages[indexPath.row].content
		}
		return cell
	}
	
	func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 30.0 + CGFloat((self.room?.messages[indexPath.row].content ?? "").characters.count) / 300.0 * 30.0
	}
	
	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return UITableViewAutomaticDimension
	}
	
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		return true
	}
	
	func chatControllerReceivedNewMessageNotificationHandler(notification: NSNotification) {
		if let room = self.room,
			let message = notification.userInfo?[ChatControllerMessageNotificationKey] as? Message {
				let index = room.addMessage(message)
				self.tableView.beginUpdates()
				self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
				self.tableView.endUpdates()
		}
	}
	
	func keyboardWillChangeFrameNotificationHandler(notification: NSNotification) {
		if let endFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue(),
			let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSTimeInterval,
			let curveRawValue = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? Int,
			let curve = UIViewAnimationCurve(rawValue: curveRawValue)
		{
			self.messageTextFieldBottomConstraint.constant = UIScreen.mainScreen().bounds.size.height - endFrame.origin.y
			UIView.animateWithDuration(duration, delay: 0.0, options: UIAnimationOptionsFromCurve(curve), animations: { () -> Void in
				self.view.layoutIfNeeded()
			}, completion: nil)
		}
	}
}
