//
//  ChatController.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit
import SocketIO

public let ChatControllerUserJoinedRoomNotification = "ChatControllerUserJoinedRoomNotification"
public let ChatControllerUserLeftRoomNotification = "ChatControllerUserLeftRoomNotification"

public let ChatControllerUserTypingNotification = "ChatControllerUserTypingNotification"
public let ChatControllerUserStoppedTypingNotification = "ChatControllerUserStoppedTypingNotification"

public let ChatControllerReceivedNewMessageNotification = "ChatControllerReceivedNewMessageNotification"

public let ChatControllerUserNotificationKey = "ChatControllerUserNotificationKey"
public let ChatControllerRoomNotificationKey = "ChatControllerRoomNotificationKey"
public let ChatControllerMessageNotificationKey = "ChatControllerMessageNotificationKey"

public class ChatController: NSObject {
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
	
	let host: String
	let port: NSNumber?
	private(set) var connectedUser: User?
	
	private func getConnectedUser() throws -> User {
		guard let connectedUser = self.connectedUser else {
			throw ErrorCode.NotConnected
		}
		return connectedUser
	}
	
	public convenience override init() {
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
// MARK: Connection/Deconnection
extension ChatController {
	public func connectWithUser(user: User, timeout: Int = Configuration.defaultTimeout, completionHandler: ((error: ErrorType?) -> ())?) {
		guard let authToken = user.authToken else {
			fatalError("Given non-authenticated user \(user.username) to ChatController.connectWithUser()")
		}
		
		var socketURL = self.host
		if let port = self.port {
			socketURL += ":\(port)"
		}
		let socket = SocketIOClient(socketURL: socketURL, opts: ["connectParams": ["token": authToken]])
		
		socket.on("connect") { data, ack in
			self.connectedUser = user
			completionHandler?(error: nil)
		}
		socket.connect(timeoutAfter: timeout) { () -> Void in
			socket.off("connect")
			self.connectedUser = nil
			completionHandler?(error: ErrorCode.ImpossibleToConnectToServer)
		}
		socket.on("disconnect") { data, ack in
			self.connectedUser = nil
			self.cleanupHandlers()
		}
		
		socket.onAny { event in
			print(event)
		}
		
		self.socketHandlerManager = SocketUniqueHandlerManager(socket: socket)
		self.socketInternal = socket
		
		self.handleNotificationEvents()
	}
	
	public func disconnect() {
		self.socketHandlerManager = nil
		self.connectedUser = nil
		if let socket = try? self.getSocket() {
			socket.disconnect()
			self.cleanupHandlers()
			self.socketInternal = nil
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
				
				completionHandler?(room: try Room.mapFromJSON(json), error: nil)
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
	
	public func sendMessage(message: String, roomUUID: NSUUID, completionHandler: ((message: Message?, error: ErrorType?) -> ())? = nil) throws {
		let user = try self.getConnectedUser()
		var parameters = try self.parametersForRoom(roomUUID: roomUUID)
		parameters["message"] = message
		try self.emitAndListenForEvent(emitEvent: "newMessage", parameters: parameters, listenForValidationError: true) { (data, error) -> () in
			do {
				if let error = error {
					throw error
				}
				
				let message = Message(messageID: nil, content: message, roomID: roomUUID, sender: user, dateSent: NSDate())
				completionHandler?(message: message, error: nil)
				dispatch_async(dispatch_get_main_queue()) {
					self.sendReceivedNewMessageNotification(message)
				}
			} catch {
				completionHandler?(message: nil, error: error)
			}
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
		]
	}
}

// MARK: Notification helpers
extension ChatController {
	private func handleNotificationEvents() {
		if let socket = self.socketInternal {
			socket.on("userJoined") { (data, ack) -> Void in
				guard let json = data.first as? JSON else {
					return
				}
				
				if let user = try? User.mapFromJSON(json), let room = try? Room.mapFromJSON(json) {
					self.sendUserJoinedRoomNotification(user, room: room)
				}
			}
			
			socket.on("userLeft") { (data, ack) -> Void in
				guard let json = data.first as? JSON else {
					return
				}
				
				if let user = try? User.mapFromJSON(json), let room = try? Room.mapFromJSON(json) {
					self.sendUserLeftRoomNotification(user, room: room)
				}
			}
			
			socket.on("typing") { (data, ack) -> Void in
				guard let json = data.first as? JSON else {
					return
				}
				
				if let user = try? User.mapFromJSON(json) {
					self.sendUserTypingNotification(user)
				}
			}
			
			socket.on("stopTyping") { (data, ack) -> Void in
				guard let json = data.first as? JSON else {
					return
				}
				
				if let user = try? User.mapFromJSON(json) {
					self.sendUserStoppedTypingNotification(user)
				}
			}
			
			socket.on("newMessage") { (data, ack) -> Void in
				guard let json = data.first as? JSON else {
					return
				}
				
				if let message = try? Message.mapFromJSON(json) {
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
			let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
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
