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
	case NotConnected
	case Connecting
	case Disconnected
	case Reconnecting
	case Connected
}

public class ChatController {
	private var socketInternal: SocketIOClient?
	private func getSocket() throws -> SocketIOClient {
		guard let socketInternal = self.socketInternal else {
			throw ErrorCode.NotConnected
		}
		if socketInternal.status != .Connected {
			throw ErrorCode.NotConnected
		}
		return socketInternal
	}
	
	private typealias CompletionHandlerType = (data: [AnyObject]?, error: ErrorType?) -> ()
	private typealias HandlersType = [String: CompletionHandlerType]
	private var handlers: HandlersType = [:]
	private lazy var handlersLock = NSLock()
	
	private var socketHandlerManager: SocketUniqueHandlerManager?
	private func getSocketHandlerManager() throws -> SocketUniqueHandlerManager {
		guard let socketHandlerManager = self.socketHandlerManager else {
			throw ErrorCode.NotConnected
		}
		return socketHandlerManager
	}
	
	public let host: String
	public let port: NSNumber?
	private(set) public var connectedUser: User?
	
	private func getConnectedUser() throws -> User {
		guard let connectedUser = self.connectedUser else {
			throw ErrorCode.NotConnected
		}
		return connectedUser
	}
	
	public var status: ConnectionStatus {
		switch(self.socketInternal?.status) {
		case .Some(.Connecting):
			return .Connecting
		case .Some(.Reconnecting):
			return .Reconnecting
		case .Some(.Connected):
			return .Connected
		default:
			return .NotConnected
		}
	}
	
	public convenience init() {
		guard let baseURL = Configuration.defaultBaseURL else {
			fatalError("ChatController(): baseURL is nil and Configuration.defaultBaseURL is nil, did you forget to set it to your base URL?")
		}
		self.init(chatServerURL: baseURL)
	}
	
	public init(chatServerURL: NSURL) {
		guard let host = chatServerURL.host else {
			fatalError("ChatController(): chatServerURL '\(chatServerURL)' doesn't have a host")
		}
		self.host = host
		self.port = chatServerURL.port
	}
}

// MARK: --- Public methods
// MARK: Login/logout
extension ChatController {
	public static func registerWithUsername(username: String, password: String, timeoutInterval: NSTimeInterval = Configuration.defaultTimeoutInterval, completionHandler: ((user: User?, error: ErrorType?) -> ())? = nil) {
		self.handleSignUpLogin(isSignUp: true, username: username, password: password, timeoutInterval: timeoutInterval, completionHandler: completionHandler)
	}
	
	public static func loginWithUsername(username: String, password: String, timeoutInterval: NSTimeInterval = Configuration.defaultTimeoutInterval, completionHandler: ((user: User?, error: ErrorType?) -> ())? = nil) {
		self.handleSignUpLogin(isSignUp: false, username: username, password: password, timeoutInterval: timeoutInterval, completionHandler: completionHandler)
	}
	
	private static func handleSignUpLogin(isSignUp signUp: Bool, username: String, password: String, timeoutInterval: NSTimeInterval = Configuration.defaultTimeoutInterval, completionHandler: ((user: User?, error: ErrorType?) -> ())? = nil) {
		WhiteLabelHTTPClient.sharedClient.sendRequest(.POST, path: signUp ? "sign-up/" : "auth/", parameters: ["username": username, "password": password], timeoutInterval: timeoutInterval) { (data, error) -> () in
			if let error = error {
				completionHandler?(user: nil, error: error)
				return
			}
			
			guard let data = data else {
				completionHandler?(user: nil, error: nil)
				return
			}
			
			let user: User
			do {
				if data["token"] as? String == nil {
					throw ErrorCode.IncompleteJSON
				}
				
				user = try mapUserFromJSON(data)
			} catch {
				completionHandler?(user: nil, error: error)
				return
			}
			
			completionHandler?(user: user, error: nil)
		}
	}
}

// MARK: Connection/Deconnection
extension ChatController {
	public func connectWithUser(user: User, timeoutInterval: NSTimeInterval = Configuration.defaultTimeoutInterval, var completionHandler: ((error: ErrorType?) -> ())? = nil) {
		guard let authToken = user.authToken else {
			fatalError("Given non-authenticated user \(user.username) to ChatController.connectWithUser()")
		}
		
		var socketURL = self.host
		if let port = self.port {
			socketURL += ":\(port)"
		}
		let socket = SocketIOClient(socketURL: socketURL, opts: ["connectParams": ["token": authToken]])
		socket.reconnectWait = 2
		
		self.connectedUser = user
		
		let socketHandlerManager = SocketUniqueHandlerManager(socket: socket)
		let connectOnceUUID = socketHandlerManager.on("connect") { (uuid, data) -> Void in
			socketHandlerManager.off("connect", handlerUUID: uuid)
			completionHandler?(error: nil)
		}
		let connectNotificationUUID = socketHandlerManager.on("connect") { (uuid, data) -> Void in
			NSNotificationCenter.defaultCenter().postNotificationName(ChatControllerDidConnectNotification, object: self)
		}
		socket.connect(timeoutAfter: Int(round(timeoutInterval))) { () -> Void in
			socketHandlerManager.off("connect", handlerUUIDs: connectOnceUUID, connectNotificationUUID)
			if let completionHandler = completionHandler {
				LogManager.sharedManager.log(.Error, message: "Error connecting to chat server")
				completionHandler(error: ErrorCode.ImpossibleToConnectToServer)
			}
			completionHandler = nil
		}
		socketHandlerManager.on("disconnect") { data, ack in
			if let completionHandler = completionHandler {
				LogManager.sharedManager.log(.Error, message: "Error connecting to chat server")
				completionHandler(error: ErrorCode.ImpossibleToConnectToServer)
			}
			completionHandler = nil
			NSNotificationCenter.defaultCenter().postNotificationName(ChatControllerDidDisconnectNotification, object: self)
		}
		socketHandlerManager.on("reconnect") { data, ack in
			NSNotificationCenter.defaultCenter().postNotificationName(ChatControllerReconnectingNotification, object: self)
		}
		
		socket.onAny { event in
			LogManager.sharedManager.log(.Debug, message: "Received event \(event.event) with items \(event.items)")
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
			dispatch_async(dispatch_get_main_queue()) {
				NSNotificationCenter.defaultCenter().postNotificationName(ChatControllerDidDisconnectNotification, object: self)
			}
		}
	}
}

// MARK: Public API
extension ChatController {
	public func joinRoom(roomUUID roomUUID: NSUUID, completionHandler: ((room: Room?, error: ErrorType?) -> ())? = nil) throws {
		let parameters = try self.parametersForRoom(roomUUID: roomUUID)
		try self.emitAndListenForEvent(emitEvent: "joinRoom", parameters: parameters, listenEvent: "joinedRoom", listenForValidationError: true) { (data, error) -> () in
			do {
				if let error = error {
					throw error
				}
				
				guard let json = data?.first as? JSON else {
					throw ErrorCode.InvalidResponseReceived
				}
				
				let room = try mapRoomFromJSON(json)
				completionHandler?(room: room, error: nil)
			} catch {
				completionHandler?(room: nil, error: error)
			}
		}
	}
	
	public func leaveRoom(roomUUID roomUUID: NSUUID, completionHandler: ((error: ErrorType?) -> ())? = nil) throws {
		let parameters = try self.parametersForRoom(roomUUID: roomUUID)
		try self.emitAndListenForEvent(emitEvent: "leaveRoom", parameters: parameters, listenForValidationError: true) { (data, error) -> () in
			completionHandler?(error: error)
		}
	}
	
	// This method will join the specified room if the connected user hasn't joined it yet
	public func messagesInRoom(roomUUID roomUUID: NSUUID, completionHandler: ((messages: [Message]?, error: ErrorType?) -> ())? = nil) throws {
		try self.joinRoom(roomUUID: roomUUID, completionHandler: { (room, error) -> () in
			completionHandler?(messages: room?.arrayOfMessages, error: error)
		})
	}
	
	public func sendMessage(message: String, roomUUID: NSUUID, completionHandler: ((message: Message?, error: ErrorType?) -> ())? = nil) throws {
		let user = try self.getConnectedUser()
		let temporaryUUID = NSUUID()
		let message = MessageFactory.sharedFactory.instanciate(messageID: temporaryUUID, content: message, roomID: roomUUID, sender: user, dateSent: NSDate())
		message.isBeingSent = true
		try self.resendMessage(message, completionHandler: completionHandler)
	}

	public func resendMessage(message: Message, completionHandler: ((message: Message?, error: ErrorType?) -> ())? = nil) throws {
		if !message.isBeingSent {
			completionHandler?(message: message, error: ErrorCode.MessageAlreadySent)
			return
		}
		
		var parameters = try self.parametersForRoom(roomUUID: message.roomID)
		parameters["message"] = message.content
		do {
			try self.emitAndListenForEvent(emitEvent: "newMessage", parameters: parameters, listenForValidationError: true) { (data, error) -> () in
				do {
					if let error = error {
						throw error
					}
					
					dispatch_async(dispatch_get_main_queue()) {
						do {
							let parameters = try self.parametersForRoom(roomUUID: message.roomID)
							try self.emitAndListenForEvent(emitEvent: "joinRoom", parameters: parameters, listenEvent: "joinedRoom", listenForValidationError: true) { (data, error) -> () in
								do {
									if let error = error {
										throw error
									}
									
									guard let json = data?.first as? JSON,
										let messages = json["messages"] as? [[String: AnyObject]]
										where messages.count > 0 else
									{
										throw ErrorCode.InvalidResponseReceived
									}
									
									let sortedMessages = messages.map { (message) -> ([String: AnyObject], NSDate?) in
										if let sent = message["sent"] as? String {
											return (message, ISO8601DateFormatter.dateFromString(sent))
										}
										return (message, nil)
										}.sort { messageWithDate1, messageWithDate2 in
											if let date1 = messageWithDate1.1 {
												if let date2 = messageWithDate2.1 {
													return date1.laterDate(date2) == date1
												}
												return true
											} else if messageWithDate2.1 != nil {
												return true
											}
											return false
									}
									
									guard let remoteMessage = sortedMessages.filter({ $0.0["message"] as? String == message.content }).first else {
										LogManager.sharedManager.log(.Error, message: "Couldn't find message \(message) in remote messages: \(messages)")
										throw ErrorCode.InvalidResponseReceived
									}
									
									LogManager.sharedManager.log(.Debug, message: "Updating temporary message \(message) with actual message \(remoteMessage)")
									
									try mapMessageFromJSON(remoteMessage.0, withExistingMessage: message)
									message.isBeingSent = false
									
									LogManager.sharedManager.log(.Debug, message: "Final message \(message)")
									
									completionHandler?(message: message, error: nil)
									self.sendReceivedNewMessageNotification(message)
								} catch {
									completionHandler?(message: nil, error: ErrorCode.CannotSendMessage(message: message, innerError: error))
								}
							}
						} catch {
							dispatch_async(dispatch_get_main_queue()) {
								completionHandler?(message: nil, error: ErrorCode.CannotSendMessage(message: message, innerError: error))
							}
						}
					}
				} catch {
					dispatch_async(dispatch_get_main_queue()) {
						completionHandler?(message: nil, error: ErrorCode.CannotSendMessage(message: message, innerError: error))
					}
				}
			}
		} catch {
			throw ErrorCode.CannotSendMessage(message: message, innerError: error)
		}
	}
	
	public func sendStartTypingIndicator(roomUUID roomUUID: NSUUID, completionHandler: ((error: ErrorType?) -> ())? = nil) throws {
		let parameters = try self.parametersForRoom(roomUUID: roomUUID)
		try self.emitAndListenForEvent(emitEvent: "typing", parameters: parameters, listenForValidationError: true) { (data, error) -> () in
			completionHandler?(error: error)
		}
	}
	
	public func sendStopTypingIndicator(roomUUID roomUUID: NSUUID, completionHandler: ((error: ErrorType?) -> ())? = nil) throws {
		let parameters = try self.parametersForRoom(roomUUID: roomUUID)
		try self.emitAndListenForEvent(emitEvent: "stopTyping", parameters: parameters, listenForValidationError: true) { (data, error) -> () in
			completionHandler?(error: error)
		}
	}
}

// MARK: --- Private methods
// MARK: Utility methods
extension ChatController {
	private func parametersForRoom(roomUUID roomUUID: NSUUID) throws -> [String: NSObject] {
		let user = try self.getConnectedUser()
		guard let userPhoto = user.userPhoto else {
			throw ErrorCode.RequiresUserPhoto
		}
		return [
			"room": roomUUID.UUIDString,
			"username": user.username,
			"userPhoto": userPhoto.absoluteString,
			"userProfileId": user.userID,
		]
	}
}

// MARK: Notification helpers
extension ChatController {
	private func handleNotificationEvents() {
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
	
	private func sendUserJoinedRoomNotification(user: User, room: Room) {
		NSNotificationCenter.defaultCenter().postNotificationName(ChatControllerUserJoinedRoomNotification, object: self, userInfo:
			[
				ChatControllerUserNotificationKey: user,
				ChatControllerRoomNotificationKey: room,
			])
	}
	
	private func sendUserLeftRoomNotification(user: User, room: Room) {
		NSNotificationCenter.defaultCenter().postNotificationName(ChatControllerUserLeftRoomNotification, object: self, userInfo:
			[
				ChatControllerUserNotificationKey: user,
				ChatControllerRoomNotificationKey: room,
			])
	}
	
	private func sendUserTypingNotification(user: User) {
		NSNotificationCenter.defaultCenter().postNotificationName(ChatControllerUserTypingNotification, object: self, userInfo:
			[
				ChatControllerUserNotificationKey: user,
			])
	}
	
	private func sendUserStoppedTypingNotification(user: User) {
		NSNotificationCenter.defaultCenter().postNotificationName(ChatControllerUserStoppedTypingNotification, object: self, userInfo:
			[
				ChatControllerUserNotificationKey: user,
			])
	}
	
	private func sendReceivedNewMessageNotification(message: Message) {
		NSNotificationCenter.defaultCenter().postNotificationName(ChatControllerReceivedNewMessageNotification, object: self, userInfo:
			[
				ChatControllerMessageNotificationKey: message,
			])
	}
}

// MARK: Emit/Listen helpers
extension ChatController {
	private func emitAndListenForEvent(emitEvent emitEvent: String, parameters: [String: NSObject]? = nil, listenEvent: String? = nil, listenForValidationError: Bool = false, completionHandler: CompletionHandlerType? = nil) throws {
		LogManager.sharedManager.log(.Debug, message: "\(emitEvent): emitting event")
		if let parameters = parameters {
			LogManager.sharedManager.log(.Debug, message: "\(emitEvent): with parameters \(parameters)")
		}
		if let listenEvent = listenEvent {
			LogManager.sharedManager.log(.Debug, message: "\(emitEvent): listen for event \(listenEvent)")
		}
		if listenForValidationError {
			LogManager.sharedManager.log(.Debug, message: "\(emitEvent): listening for validation error")
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
	
	private func listenForEvent(event: String? = nil, validationErrorObject: [String: NSObject]? = nil, completionHandler: CompletionHandlerType) throws {
		if event == nil && validationErrorObject == nil {
			dispatch_async(dispatch_get_main_queue()) {
				completionHandler(data: nil, error: nil)
			}
			return
		}
		
		let socketHandlerManager = try getSocketHandlerManager()
		let uuid = NSUUID()
		self.lockHandlers {
			self.handlers[uuid.UUIDString] = completionHandler
		}
		
		if let validationErrorObject = validationErrorObject {
			socketHandlerManager.on("validationError", handlerUUID: uuid) { (handlerUUID, data) in
				if let handler = self.handlerForUUID(uuid) {
					let response = data.first as? [String: AnyObject]
					
					if let object = response?["_object"] as? [String: NSObject] where validationErrorObject != object {
						return
					}
					
					self.lockHandlers {
						self.handlers.removeValueForKey(uuid.UUIDString)
					}
					
					let details = response?["details"] as? [[String: AnyObject]]
					let message = details?.first?["message"] as? String
					dispatch_async(dispatch_get_main_queue()) {
						handler(data: nil, error: ErrorCode.ValidationError(message: message ?? "Unknown error"))
					}
				}
				socketHandlerManager.off("validationError", handlerUUID: uuid)
				if let event = event {
					socketHandlerManager.off(event, handlerUUID: uuid)
				}
			}
		}
		
		let eventHandler: (data: [AnyObject]?) -> () = { (data) in
			if let handler = self.handlerForUUID(uuid) {
				self.lockHandlers {
					self.handlers.removeValueForKey(uuid.UUIDString)
				}
				dispatch_async(dispatch_get_main_queue()) {
					handler(data: data, error: nil)
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
				eventHandler(data: data)
			}
		} else {
			let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(NSEC_PER_SEC)))
			dispatch_after(delayTime, dispatch_get_main_queue()) {
				eventHandler(data: nil)
			}
		}
	}
}

// MARK: Completion Handler helpers
extension ChatController {
	private func cleanupHandlers() {
		dispatch_async(dispatch_get_main_queue()) {
			for (_, handler) in self.handlers {
				handler(data: nil, error: ErrorCode.Disconnected)
			}
		}
		self.handlers.removeAll()
		if let socket = try? self.getSocket() {
			socket.removeAllHandlers()
		}
	}
	
	private func lockHandlers<T>(action: () throws -> T) rethrows -> T {
		self.handlersLock.lock()
		defer { self.handlersLock.unlock() }
		return try action()
	}
	
	private func handlerForUUID(uuid: NSUUID) -> CompletionHandlerType? {
		return self.lockHandlers {
			return self.handlers[uuid.UUIDString]
		}
	}
}
