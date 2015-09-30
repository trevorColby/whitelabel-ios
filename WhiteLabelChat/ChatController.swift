//
//  ChatController.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit
import SocketIO

private class SocketUniqueHandlerManager {
	private let socket: SocketIOClient
	
	private lazy var handlersLock = NSLock()
	typealias CompletionHandlerType = (uuid: NSUUID, data: [AnyObject]) -> Void
	typealias HandlersType = [String: CompletionHandlerType]
	typealias EventHandlersType = [String: HandlersType]
	private var handlers: EventHandlersType = [:]
	
	init(socket: SocketIOClient) {
		self.socket = socket
	}
	
	func on(event: String, handlerUUID: NSUUID = NSUUID(), completion: CompletionHandlerType) -> NSUUID {
		if var handlers = self.handlersForEvent(event) {
			handlers[handlerUUID.UUIDString] = completion
			
			self.lockHandlers {
				self.handlers[event] = handlers
			}
		} else {
			self.lockHandlers {
				self.handlers[event] = [handlerUUID.UUIDString: completion]
			}
			
			self.socket.on(event) { (data, ack) in
				if let handlers = self.handlersForEvent(event) {
					for (_, handler) in handlers {
						handler(uuid: handlerUUID, data: data)
					}
				}
			}
		}
		return handlerUUID
	}
	
	func off(event: String, handlerUUID: NSUUID) {
		if var handlers = self.handlersForEvent(event) {
			handlers.removeValueForKey(handlerUUID.UUIDString)
			
			self.lockHandlers {
				self.handlers[event] = handlers
			}
			
			if handlers.isEmpty {
				self.socket.off(event)
			}
		}
	}
	
	private func lockHandlers<T>(action: () -> T) -> T {
		self.handlersLock.lock()
		defer { self.handlersLock.unlock() }
		return action()
	}
	
	private func handlersForEvent(event: String) -> HandlersType? {
		return self.lockHandlers {
			return self.handlers[event]
		}
	}
}

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
	
	private var handlers: [String: (error: ErrorType?) -> ()] = [:]
	private lazy var handlersLock = NSLock()
	
	private var socketHandlerManager: SocketUniqueHandlerManager?
	private func getSocketHandlerManager() throws -> SocketUniqueHandlerManager {
		guard let socketHandlerManager = self.socketHandlerManager else {
			throw ErrorCode.NotConnected
		}
		return socketHandlerManager
	}
	
	let chatServerURL: NSURL
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
		self.chatServerURL = chatServerURL
	}
	
	public func connectWithUser(user: User, timeout: Int = Configuration.defaultTimeout, completionHandler: ((error: ErrorType?) -> ())?) {
		guard let authToken = user.authToken else {
			fatalError("Given non-authenticated user \(user.username) to ChatController.connectWithUser()")
		}
		
		let socket = SocketIOClient(socketURL: "localhost:3000", opts: ["connectParams": ["token": authToken]])
		
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
	
	public func joinRoom(roomUUID roomUUID: NSUUID, userPhoto: String? = nil, completionHandler: ((error: ErrorType?) -> ())? = nil) throws {
		let socket = try self.getSocket()
		let user = try self.getConnectedUser()
		var parameters = [
			"room": roomUUID.UUIDString,
			"username": user.username,
		]
		if let userPhoto = userPhoto {
			parameters["userPhoto"] = userPhoto
		}
		socket.emit("joinRoom", parameters)
		if let completionHandler = completionHandler {
			try self.listenForEvent("joinedRoom", validationErrorObject: parameters, completionHandler: completionHandler)
		}
	}
	
	public func sendMessage(message: String, roomUUID: NSUUID, userPhoto: String? = nil, completionHandler: ((error: ErrorType?) -> ())? = nil) throws {
		let socket = try self.getSocket()
		let user = try self.getConnectedUser()
		var parameters = [
			"message": message,
			"room": roomUUID.UUIDString,
			"username": user.username,
		]
		if let userPhoto = userPhoto {
			parameters["userPhoto"] = userPhoto
		}
		socket.emit("newMessage", parameters)
		if let completionHandler = completionHandler {
			try self.listenForEvent(validationErrorObject: parameters, completionHandler: completionHandler)
		}
	}
	
	private func emitAndListenForEvent(emitEvent emitEvent: String, listenEvent: String? = nil, validationErrorObject: [String: NSObject]? = nil, completionHandler: ((error: ErrorType?) -> ())? = nil) throws {
		let socket = try self.getSocket()
		socket.emit(emitEvent)
		if let completionHandler = completionHandler {
			try self.listenForEvent(listenEvent, validationErrorObject: validationErrorObject, completionHandler: completionHandler)
		}
	}
	
	private func listenForEvent(event: String? = nil, validationErrorObject: [String: NSObject]? = nil, completionHandler: (error: ErrorType?) -> ()) throws {
		if event == nil && validationErrorObject == nil {
			dispatch_async(dispatch_get_main_queue()) {
				completionHandler(error: nil)
			}
			return
		}
		
		let socketHandlerManager = try getSocketHandlerManager()
		let uuid = NSUUID()
		try self.lockHandlers {
			self.handlers[uuid.UUIDString] = completionHandler
		}
		
		if let validationErrorObject = validationErrorObject {
			socketHandlerManager.on("validationError", handlerUUID: uuid) { (handlerUUID, data) in
				do {
					if let handler = try self.handlerForUUID(uuid) {
						do {
							let response = data.first as? [String: AnyObject]
							
							if let object = response?["_object"] as? [String: NSObject] where validationErrorObject != object {
								return
							}
							
							try self.lockHandlers {
								self.handlers.removeValueForKey(uuid.UUIDString)
							}
							
							let details = response?["details"] as? [[String: AnyObject]]
							let message = details?.first?["message"] as? String
							handler(ErrorCode.ValidationError(message: message ?? "Unknown error"))
						} catch {
							handler(error)
						}
					}
					socketHandlerManager.off("validationError", handlerUUID: uuid)
					if let event = event {
						socketHandlerManager.off(event, handlerUUID: uuid)
					}
				} catch {
					fatalError("Couldn't lock handlers: \(error)")
				}
			}
		}
		
		let eventHandler: (data: [AnyObject]?) -> () = { (data) in
			do {
				if let handler = try self.handlerForUUID(uuid) {
					do {
						try self.lockHandlers {
							self.handlers.removeValueForKey(uuid.UUIDString)
						}
						handler(nil)
					} catch {
						handler(error)
					}
				}
				
				if validationErrorObject != nil {
					socketHandlerManager.off("validationError", handlerUUID: uuid)
				}
				if let event = event {
					socketHandlerManager.off(event, handlerUUID: uuid)
				}
			} catch {
				fatalError("Couldn't lock handlers: \(error)")
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
	
	private func cleanupHandlers() {
		for (_, handler) in self.handlers {
			handler(error: ErrorCode.Disconnected)
		}
		self.handlers.removeAll()
		if let socket = try? self.getSocket() {
			socket.removeAllHandlers()
		}
	}
	
	private func lockHandlers<T>(action: () throws -> T) throws -> T {
		self.handlersLock.lock()
		defer { self.handlersLock.unlock() }
		return try action()
	}
	
	private func handlerForUUID(uuid: NSUUID) throws -> ((ErrorType?) -> ())? {
		return try self.lockHandlers {
			return self.handlers[uuid.UUIDString]
		}
	}
}
