//
//  ChatController.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit
import SocketIO

public let ChatControllerDidConnectNotification = "ChatControllerDidConnectNotification"
public let ChatControllerReconnectingNotification = "ChatControllerReconnectingNotification"
public let ChatControllerDidDisconnectNotification = "ChatControllerDidDisconnectNotification"

public let ChatControllerUserJoinedRoomNotification = "ChatControllerUserJoinedRoomNotification"
public let ChatControllerUserLeftRoomNotification = "ChatControllerUserLeftRoomNotification"

public let ChatControllerUserTypingNotification = "ChatControllerUserTypingNotification"
public let ChatControllerUserStoppedTypingNotification = "ChatControllerUserStoppedTypingNotification"

public let ChatControllerReceivedNewMessageNotification = "ChatControllerReceivedNewMessageNotification"

public let ChatControllerUserNotificationKey = "ChatControllerUserNotificationKey"
public let ChatControllerRoomNotificationKey = "ChatControllerRoomNotificationKey"
public let ChatControllerMessageNotificationKey = "ChatControllerMessageNotificationKey"

public enum ConnectionStatus {
	case notConnected
	case connecting
	case disconnected
	case connected
}

open class ChatController {
	fileprivate var socketInternal: SocketIOClient?
	fileprivate func getSocket() throws -> SocketIOClient {
		guard let socketInternal = self.socketInternal else {
			throw ErrorCode.notConnected
		}
		if socketInternal.status != .connected {
			throw ErrorCode.notConnected
		}
		return socketInternal
	}
	
	fileprivate typealias CompletionHandlerType = (_ data: [AnyObject]?, _ error: Error?) -> ()
	fileprivate typealias HandlersType = [String: CompletionHandlerType]
	fileprivate var handlers: HandlersType = [:]
	fileprivate lazy var handlersLock = NSLock()
	
	fileprivate var socketHandlerManager: SocketUniqueHandlerManager?
	fileprivate func getSocketHandlerManager() throws -> SocketUniqueHandlerManager {
		guard let socketHandlerManager = self.socketHandlerManager else {
			throw ErrorCode.notConnected
		}
		return socketHandlerManager
	}
	
	open let chatServerURL: URL
	fileprivate(set) open var connectedUser: User?
	
	fileprivate func getConnectedUser() throws -> User {
		guard let connectedUser = self.connectedUser else {
			throw ErrorCode.notConnected
		}
		return connectedUser
	}
	
	open var status: ConnectionStatus {
		switch(self.socketInternal?.status) {
		case .some(.connecting):
			return .connecting
		case .some(.connected):
			return .connected
		default:
			return .notConnected
		}
	}
	
	public convenience init() {
		guard let baseURL = Configuration.defaultBaseURL else {
			fatalError("ChatController(): baseURL is nil and Configuration.defaultBaseURL is nil, did you forget to set it to your base URL?")
		}
		self.init(chatServerURL: baseURL as URL)
	}
	
	public init(chatServerURL: URL) {
		self.chatServerURL = chatServerURL
	}
}

// MARK: --- Public methods
// MARK: Login/logout
extension ChatController {
	public static func registerWithUsername(_ username: String, password: String, timeoutInterval: TimeInterval = Configuration.defaultTimeoutInterval, completionHandler: ((_ user: User?, _ error: Error?) -> ())? = nil) {
		self.handleSignUpLogin(isSignUp: true, username: username, password: password, timeoutInterval: timeoutInterval, completionHandler: completionHandler)
	}
	
	public static func loginWithUsername(_ username: String, password: String, timeoutInterval: TimeInterval = Configuration.defaultTimeoutInterval, completionHandler: ((_ user: User?, _ error: Error?) -> ())? = nil) {
		self.handleSignUpLogin(isSignUp: false, username: username, password: password, timeoutInterval: timeoutInterval, completionHandler: completionHandler)
	}
	
	fileprivate static func handleSignUpLogin(isSignUp signUp: Bool, username: String, password: String, timeoutInterval: TimeInterval = Configuration.defaultTimeoutInterval, completionHandler: ((_ user: User?, _ error: Error?) -> ())? = nil) {
		WhiteLabelHTTPClient.sharedClient.sendRequest(.POST, path: signUp ? "sign-up/" : "auth/", parameters: ["username": username as AnyObject, "password": password as AnyObject], timeoutInterval: timeoutInterval) { (data, error) -> () in
			if let error = error {
				completionHandler?(nil, error)
				return
			}
			
			guard let data = data else {
				completionHandler?(nil, nil)
				return
			}
			
			let user: User
			do {
				if data["token"] as? String == nil {
					throw ErrorCode.incompleteJSON
				}
				
				user = try mapUserFromJSON(data)
			} catch {
				completionHandler?(nil, error)
				return
			}
			
			completionHandler?(user, nil)
		}
	}
}

// MARK: Connection/Deconnection
extension ChatController {
	public func connectWithUser(_ user: User, timeoutInterval: TimeInterval = Configuration.defaultTimeoutInterval, completionHandler: ((_ error: Error?) -> ())? = nil) {
		guard let authToken = user.authToken else {
			fatalError("Given non-authenticated user \(user.username) to ChatController.connectWithUser()")
		}

		let socket = SocketIOClient(socketURL: self.chatServerURL, config: [.connectParams(["token": authToken])])
		socket.reconnectWait = 2
		
		self.connectedUser = user
		
		let socketHandlerManager = SocketUniqueHandlerManager(socket: socket)
		let connectOnceUUID = socketHandlerManager.on("connect") { (uuid, data) -> Void in
			socketHandlerManager.off("connect", handlerUUID: uuid)
			completionHandler?(nil)
		}
		let connectNotificationUUID = socketHandlerManager.on("connect") { (uuid, data) -> Void in
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: ChatControllerDidConnectNotification), object: self)
		}
		var completionHandler = completionHandler
		socket.connect(timeoutAfter: Int(round(timeoutInterval))) { () -> Void in
			socketHandlerManager.off("connect", handlerUUIDs: connectOnceUUID, connectNotificationUUID)
			if let completionHandler = completionHandler {
				LogManager.sharedManager.log(.error, message: "Error connecting to chat server")
				completionHandler(ErrorCode.impossibleToConnectToServer)
			}
			completionHandler = nil
		}
		socketHandlerManager.on("disconnect") { data, ack in
			if let completionHandler = completionHandler {
				LogManager.sharedManager.log(.error, message: "Error connecting to chat server")
				completionHandler(ErrorCode.impossibleToConnectToServer)
			}
			completionHandler = nil
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: ChatControllerDidDisconnectNotification), object: self)
		}
		socketHandlerManager.on("reconnect") { data, ack in
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: ChatControllerReconnectingNotification), object: self)
		}
		
		socket.onAny { event in
			LogManager.sharedManager.log(.debug, message: "Received event \(event.event) with items \(event.items)")
		}
		
		self.socketHandlerManager = socketHandlerManager
		self.socketInternal = socket
		
		self.handleNotificationEvents()
	}
	
	public func disconnect() {
		self.cleanupHandlers()
		self.socketHandlerManager = nil
		self.connectedUser = nil
		if let socket = try? self.getSocket() {
			socket.disconnect()
		} else {
			DispatchQueue.main.async {
				NotificationCenter.default.post(name: Notification.Name(rawValue: ChatControllerDidDisconnectNotification), object: self)
			}
		}
	}
}

// MARK: Public API
extension ChatController {
	public func joinRoom(roomUUID: UUID, completionHandler: ((_ room: Room?, _ error: Error?) -> ())? = nil) throws {
		let parameters = try self.parametersForRoom(roomUUID: roomUUID)
		try self.emitAndListenForEvent(emitEvent: "joinRoom", parameters: parameters, listenEvent: "joinedRoom", listenForValidationError: true) { (data, error) -> () in
			do {
				if let error = error {
					throw error
				}
				
				guard let json = data?.first as? JSON else {
					throw ErrorCode.invalidResponseReceived
				}
				
				let room = try mapRoomFromJSON(json)
				completionHandler?(room, nil)
			} catch {
				completionHandler?(nil, error)
			}
		}
	}
	
	public func leaveRoom(roomUUID: UUID, completionHandler: ((_ error: Error?) -> ())? = nil) throws {
		let parameters = try self.parametersForRoom(roomUUID: roomUUID)
		try self.emitAndListenForEvent(emitEvent: "leaveRoom", parameters: parameters, listenForValidationError: true) { (data, error) -> () in
			completionHandler?(error)
		}
	}
	
	// This method will join the specified room if the connected user hasn't joined it yet
	public func messagesInRoom(roomUUID: UUID, completionHandler: ((_ messages: [Message]?, _ error: Error?) -> ())? = nil) throws {
		try self.joinRoom(roomUUID: roomUUID, completionHandler: { (room, error) -> () in
			completionHandler?(room?.arrayOfMessages, error)
		})
	}
	
	public func sendMessage(_ message: String, roomUUID: UUID, completionHandler: ((_ message: Message?, _ error: Error?) -> ())? = nil) throws {
		let user = try self.getConnectedUser()
		let temporaryUUID = UUID()
		let message = MessageFactory.sharedFactory.instanciate(messageID: temporaryUUID, content: message, roomID: roomUUID, sender: user, dateSent: Date())
		message.isBeingSent = true
		try self.resendMessage(message, completionHandler: completionHandler)
	}

	public func resendMessage(_ message: Message, completionHandler: ((_ message: Message?, _ error: Error?) -> ())? = nil) throws {
		if !message.isBeingSent {
			completionHandler?(message, ErrorCode.messageAlreadySent)
			return
		}
		
		var parameters = try self.parametersForRoom(roomUUID: message.roomID as UUID)
		parameters["message"] = message.content as NSObject?
		do {
			try self.emitAndListenForEvent(emitEvent: "newMessage", parameters: parameters, listenForValidationError: true) { (data, error) -> () in
				do {
					if let error = error {
						throw error
					}
					
					DispatchQueue.main.async {
						do {
							let parameters = try self.parametersForRoom(roomUUID: message.roomID as UUID)
							try self.emitAndListenForEvent(emitEvent: "joinRoom", parameters: parameters, listenEvent: "joinedRoom", listenForValidationError: true) { (data, error) -> () in
								do {
									if let error = error {
										throw error
									}
									
									guard let json = data?.first as? JSON,
										let messages = json["messages"] as? [[String: AnyObject]], messages.count > 0 else
									{
										throw ErrorCode.invalidResponseReceived
									}
									
									let sortedMessages = messages.map { (message) -> ([String: AnyObject], Date?) in
										if let sent = message["sent"] as? String {
											return (message, ISO8601DateFormatter.dateFromString(sent))
										}
										return (message, nil)
										}.sorted { messageWithDate1, messageWithDate2 in
											if let date1 = messageWithDate1.1 {
												if let date2 = messageWithDate2.1 {
													return (date1 as NSDate).laterDate(date2) == date1
												}
												return true
											} else if messageWithDate2.1 != nil {
												return true
											}
											return false
									}
									
									guard let remoteMessage = sortedMessages.filter({ $0.0["message"] as? String == message.content }).first else {
										LogManager.sharedManager.log(.error, message: "Couldn't find message \(message) in remote messages: \(messages)")
										throw ErrorCode.invalidResponseReceived
									}
									
									LogManager.sharedManager.log(.debug, message: "Updating temporary message \(message) with actual message \(remoteMessage)")
									
									try mapMessageFromJSON(remoteMessage.0, withExistingMessage: message)
									message.isBeingSent = false
									
									LogManager.sharedManager.log(.debug, message: "Final message \(message)")
									
									completionHandler?(message, nil)
									self.sendReceivedNewMessageNotification(message)
								} catch {
									completionHandler?(nil, ErrorCode.cannotSendMessage(message: message, innerError: error))
								}
							}
						} catch {
							DispatchQueue.main.async {
								completionHandler?(nil, ErrorCode.cannotSendMessage(message: message, innerError: error))
							}
						}
					}
				} catch {
					DispatchQueue.main.async {
						completionHandler?(nil, ErrorCode.cannotSendMessage(message: message, innerError: error))
					}
				}
			}
		} catch {
			throw ErrorCode.cannotSendMessage(message: message, innerError: error)
		}
	}
	
	public func sendStartTypingIndicator(roomUUID: UUID, completionHandler: ((_ error: Error?) -> ())? = nil) throws {
		let parameters = try self.parametersForRoom(roomUUID: roomUUID)
		try self.emitAndListenForEvent(emitEvent: "typing", parameters: parameters, listenForValidationError: true) { (data, error) -> () in
			completionHandler?(error)
		}
	}
	
	public func sendStopTypingIndicator(roomUUID: UUID, completionHandler: ((_ error: Error?) -> ())? = nil) throws {
		let parameters = try self.parametersForRoom(roomUUID: roomUUID)
		try self.emitAndListenForEvent(emitEvent: "stopTyping", parameters: parameters, listenForValidationError: true) { (data, error) -> () in
			completionHandler?(error)
		}
	}
}

// MARK: --- Private methods
// MARK: Utility methods
extension ChatController {
	fileprivate func parametersForRoom(roomUUID: UUID) throws -> [String: NSObject] {
		let user = try self.getConnectedUser()
		guard let userPhoto = user.userPhoto else {
			throw ErrorCode.requiresUserPhoto
		}
		return [
			"room": roomUUID.uuidString as NSObject,
			"username": user.username as NSObject,
			"userPhoto": userPhoto.absoluteString as NSObject,
			"userProfileId": user.userID as NSObject,
		]
	}
}

// MARK: Notification helpers
extension ChatController {
	fileprivate func handleNotificationEvents() {
		if let socketHandlerManager = self.socketHandlerManager {
			socketHandlerManager.on("userJoined") { (uuid, data) -> Void in
				guard let json = data.first as? JSON else {
					return
				}
				
				if let user = try? mapUserFromJSON(json), let room = try? mapRoomFromJSON(json) {
					self.sendUserJoinedRoomNotification(user, room: room)
				}
			}
			
			socketHandlerManager.on("userLeft") { (uuid, data) -> Void in
				guard let json = data.first as? JSON else {
					return
				}
				
				if let user = try? mapUserFromJSON(json), let room = try? mapRoomFromJSON(json) {
					self.sendUserLeftRoomNotification(user, room: room)
				}
			}
			
			socketHandlerManager.on("typing") { (uuid, data) -> Void in
				guard let json = data.first as? JSON else {
					return
				}
				
				if let user = try? mapUserFromJSON(json) {
					self.sendUserTypingNotification(user)
				}
			}
			
			socketHandlerManager.on("stopTyping") { (uuid, data) -> Void in
				guard let json = data.first as? JSON else {
					return
				}
				
				if let user = try? mapUserFromJSON(json) {
					self.sendUserStoppedTypingNotification(user)
				}
			}
			
			socketHandlerManager.on("newMessage") { (uuid, data) -> Void in
				guard let json = data.first as? JSON else {
					return
				}
				
				if let message = try? mapMessageFromJSON(json) {
					self.sendReceivedNewMessageNotification(message)
				}
			}
		}
	}
	
	fileprivate func sendUserJoinedRoomNotification(_ user: User, room: Room) {
		NotificationCenter.default.post(name: Notification.Name(rawValue: ChatControllerUserJoinedRoomNotification), object: self, userInfo:
			[
				ChatControllerUserNotificationKey: user,
				ChatControllerRoomNotificationKey: room,
			])
	}
	
	fileprivate func sendUserLeftRoomNotification(_ user: User, room: Room) {
		NotificationCenter.default.post(name: Notification.Name(rawValue: ChatControllerUserLeftRoomNotification), object: self, userInfo:
			[
				ChatControllerUserNotificationKey: user,
				ChatControllerRoomNotificationKey: room,
			])
	}
	
	fileprivate func sendUserTypingNotification(_ user: User) {
		NotificationCenter.default.post(name: Notification.Name(rawValue: ChatControllerUserTypingNotification), object: self, userInfo:
			[
				ChatControllerUserNotificationKey: user,
			])
	}
	
	fileprivate func sendUserStoppedTypingNotification(_ user: User) {
		NotificationCenter.default.post(name: Notification.Name(rawValue: ChatControllerUserStoppedTypingNotification), object: self, userInfo:
			[
				ChatControllerUserNotificationKey: user,
			])
	}
	
	fileprivate func sendReceivedNewMessageNotification(_ message: Message) {
		NotificationCenter.default.post(name: Notification.Name(rawValue: ChatControllerReceivedNewMessageNotification), object: self, userInfo:
			[
				ChatControllerMessageNotificationKey: message,
			])
	}
}

// MARK: Emit/Listen helpers
extension ChatController {
	fileprivate func emitAndListenForEvent(emitEvent: String, parameters: [String: NSObject]? = nil, listenEvent: String? = nil, listenForValidationError: Bool = false, completionHandler: CompletionHandlerType? = nil) throws {
		LogManager.sharedManager.log(.debug, message: "\(emitEvent): emitting event")
		if let parameters = parameters {
			LogManager.sharedManager.log(.debug, message: "\(emitEvent): with parameters \(parameters)")
		}
		if let listenEvent = listenEvent {
			LogManager.sharedManager.log(.debug, message: "\(emitEvent): listen for event \(listenEvent)")
		}
		if listenForValidationError {
			LogManager.sharedManager.log(.debug, message: "\(emitEvent): listening for validation error")
		}
		
		let socket = try self.getSocket()
		if let parameters = parameters {
			socket.emit(emitEvent, parameters)
		} else {
			socket.emit(emitEvent)
		}
		if let completionHandler = completionHandler {
			try self.listenForEvent(listenEvent, validationErrorObject: listenForValidationError ? parameters : nil, completionHandler: completionHandler)
		}
	}
	
	fileprivate func listenForEvent(_ event: String? = nil, validationErrorObject: [String: NSObject]? = nil, completionHandler: @escaping CompletionHandlerType) throws {
		if event == nil && validationErrorObject == nil {
			DispatchQueue.main.async {
				completionHandler(nil, nil)
			}
			return
		}
		
		let socketHandlerManager = try getSocketHandlerManager()
		let uuid = UUID()
		self.lockHandlers {
			self.handlers[uuid.uuidString] = completionHandler
		}
		
		if let validationErrorObject = validationErrorObject {
			socketHandlerManager.on("validationError", handlerUUID: uuid) { (handlerUUID, data) in
				if let handler = self.handlerForUUID(uuid) {
					let response = data.first as? [String: AnyObject]
					
					if let object = response?["_object"] as? [String: NSObject], validationErrorObject != object {
						return
					}
					
					self.lockHandlers {
						self.handlers.removeValue(forKey: uuid.uuidString)
					}
					
					let details = response?["details"] as? [[String: AnyObject]]
					let message = details?.first?["message"] as? String
					DispatchQueue.main.async {
						handler(nil, ErrorCode.validationError(message: message ?? "Unknown error"))
					}
				}
				socketHandlerManager.off("validationError", handlerUUID: uuid)
				if let event = event {
					socketHandlerManager.off(event, handlerUUID: uuid)
				}
			}
		}
		
		let eventHandler: (_ data: [AnyObject]?) -> () = { (data) in
			if let handler = self.handlerForUUID(uuid) {
				self.lockHandlers {
					self.handlers.removeValue(forKey: uuid.uuidString)
				}
				DispatchQueue.main.async {
					handler(data, nil)
				}
			}
			
			if validationErrorObject != nil {
				socketHandlerManager.off("validationError", handlerUUID: uuid)
			}
			if let event = event {
				socketHandlerManager.off(event, handlerUUID: uuid)
			}
		}
		
		if let event = event {
			socketHandlerManager.on(event) { (handlerUUID, data) in
				eventHandler(data)
			}
		} else {
			let delayTime = DispatchTime.now() + Double(Int64(0.3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
			DispatchQueue.main.asyncAfter(deadline: delayTime) {
				eventHandler(nil)
			}
		}
	}
}

// MARK: Completion Handler helpers
extension ChatController {
	fileprivate func cleanupHandlers() {
		DispatchQueue.main.async {
			for (_, handler) in self.handlers {
				handler(nil, ErrorCode.disconnected)
			}
		}
		self.handlers.removeAll()
		if let socket = try? self.getSocket() {
			socket.removeAllHandlers()
		}
	}

	@discardableResult
	fileprivate func lockHandlers<T>(action: () throws -> T) rethrows -> T {
		self.handlersLock.lock()
		defer { self.handlersLock.unlock() }
		return try action()
	}
	
	fileprivate func handlerForUUID(_ uuid: UUID) -> CompletionHandlerType? {
		return self.lockHandlers {
			return self.handlers[uuid.uuidString]
		}
	}
}
