//
//  ChatViewController.swift
//  WhiteLabelChatDemo
//
//  Created by Stephane Copin on 10/1/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit
import WhiteLabelChat
import SlackTextViewController

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

class ChatViewController: SLKTextViewController {
	private let ShowSignUpLoginViewControllerSegue = "ShowSignUpLoginViewControllerSegue"
	private let ChatMessageTableViewCellReuseIdentifier = "ChatMessageTableViewCellReuseIdentifier"
	private let RoomUUID = NSUUID(UUIDString: "6CE97FFF-224D-43D5-8BFF-8AE62204BA6C")!
	
	private var currentUser: User!
	private let chatController = ChatController()
	private var roomUUID: NSUUID?
	private var messages: [Message] = []
	private var isTyping = false
	private var isTypingTimer: NSTimer?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.tableView.registerNib(UINib(nibName: "ChatMessageTableViewCell", bundle: nil), forCellReuseIdentifier: ChatMessageTableViewCellReuseIdentifier)
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "chatControllerReceivedNewMessageNotificationHandler:", name: ChatControllerReceivedNewMessageNotification, object: self.chatController)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "chatControllerUserTypingNotification:", name: ChatControllerUserTypingNotification, object: self.chatController)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "chatControllerUserStoppedTypingNotification:", name: ChatControllerUserStoppedTypingNotification, object: self.chatController)
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
						self.roomUUID = room.roomID
						self.messages = room.arrayOfMessages
						self.reloadMessages()
					}
				}
			} catch {
				print("Couldn't join room \(self.RoomUUID.UUIDString) to chat: \(error)")
			}
		}
	}
	
	override class func tableViewStyleForCoder(decoder: NSCoder!) -> UITableViewStyle {
		return .Plain
	}
	
	override func didPressRightButton(sender: AnyObject!) {
		if let roomUUID = self.roomUUID {
			self.textView.refreshFirstResponder()
			
			if(self.isTyping) {
				do {
					try self.chatController.sendStopTypingIndicator(roomUUID: roomUUID)
				} catch {
					print("Couldn't send stop typing indicator: \(error)")
				}
				self.isTyping = false
				self.isTypingTimer?.invalidate()
				self.isTypingTimer = nil
			}
			
			do {
				try self.chatController.sendMessage(self.textView.text ?? "", roomUUID: roomUUID)
				
				super.didPressRightButton(sender)
			} catch {
				print("Couldn't send message: \(error)")
			}
		}
	}
	
	@IBAction func logoutButtonTapped(sender: AnyObject) {
		let disconnectAction: () -> () = {
			self.chatController.disconnect()
			UserHelper.logoutUser()
			self.performSegueWithIdentifier(self.ShowSignUpLoginViewControllerSegue, sender: self)
		}
		
		do {
			try self.chatController.leaveRoom(roomUUID: self.RoomUUID) { (error) in
				disconnectAction()
			}
		} catch {
			disconnectAction()
		}
	}
	
	private func reloadMessages() {
		self.tableView.reloadData()
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.messages.count ?? 0
	}
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier(ChatMessageTableViewCellReuseIdentifier, forIndexPath: indexPath) as! ChatMessageTableViewCell
		cell.usernameLabel.text = self.messages[indexPath.row].sender.username
		cell.messageLabel.text = self.messages[indexPath.row].content
		return cell
	}
	
	override func textDidUpdate(animated: Bool) {
		super.textDidUpdate(animated)
		
		do {
			if self.textView.text.characters.isEmpty {
				try self.chatController.sendStopTypingIndicator(roomUUID: self.RoomUUID)
				
				self.isTypingTimer?.invalidate()
				self.isTypingTimer = nil
			} else {
				try self.chatController.sendStartTypingIndicator(roomUUID: self.RoomUUID)
				
				self.isTypingTimer?.invalidate()
				self.isTypingTimer = NSTimer(timeInterval: 10.0, target: self, selector: "userStoppedTyping:", userInfo: nil, repeats: false)
			}
		} catch {
			print("Error sending typing indicator: \(error)")
		}
	}
	
	func userStoppedTyping(timer: NSTimer) {
		if(self.isTyping) {
			do {
				try self.chatController.sendStopTypingIndicator(roomUUID: self.RoomUUID)
			} catch {
				print("Couldn't send stop typing indicator: \(error)")
			}
			self.isTyping = false
			self.isTypingTimer?.invalidate()
			self.isTypingTimer = nil
		}
	}
	
	override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		cell.transform = self.tableView.transform
	}
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return UITableViewAutomaticDimension
	}
	
	override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 30.0 + CGFloat((self.messages[indexPath.row].content.characters.count + 99) / 100 * 30)
	}
	
	override func canShowTypingIndicator() -> Bool {
		return true
	}
	
	func chatControllerReceivedNewMessageNotificationHandler(notification: NSNotification) {
		if let message = notification.userInfo?[ChatControllerMessageNotificationKey] as? Message {
				let index = self.addMessage(message)
				self.tableView.beginUpdates()
				self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .Automatic)
				self.tableView.endUpdates()
		}
	}
	
	func chatControllerUserTypingNotification(notification: NSNotification) {
		if let user = notification.userInfo?[ChatControllerUserNotificationKey] as? User {
			self.typingIndicatorView.insertUsername(user.username)
		}
	}
	
	func chatControllerUserStoppedTypingNotification(notification: NSNotification) {
		if let user = notification.userInfo?[ChatControllerUserNotificationKey] as? User {
			self.typingIndicatorView.removeUsername(user.username)
		}
	}
	
	private func addMessage(message: Message) -> Int {
		return self.addMessages([message]).first ?? 0
	}
	
	private func addMessages(messages: [Message]) -> [Int] {
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
