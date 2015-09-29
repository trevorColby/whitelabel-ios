//
//  ChatController.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import UIKit
import SocketIO

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
	
	private var handlers: [String: (ErrorType?) -> ()] = [:]
	private lazy var handlersLock = NSLock()
	
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
		
		self.socketInternal = socket
	}
	
	public func disconnect() {
		self.connectedUser = nil
		if let socket = try? self.getSocket() {
			socket.disconnect()
			self.cleanupHandlers()
			self.socketInternal = nil
		}
	}
	
	public func joinRoom(roomKey roomKey: String, userPhoto: String? = nil, completionHandler: ((error: ErrorType?) -> ())? = nil) throws {
		let socket = try self.getSocket()
		let user = try self.getConnectedUser()
		var parameters = [
			"room": roomKey,
			"username": user.username,
		]
		if let userPhoto = userPhoto {
			parameters["userPhoto"] = userPhoto
		}
		socket.emit("joinRoom", parameters)
		if let completionHandler = completionHandler {
			try self.listenForEvent("joinedRoom", completionHandler: completionHandler)
		}
	}
	
	private func emitAndListenForEvent(emitEvent emitEvent: String, listenEvent: String? = nil, listenForValidationError: Bool = false, completionHandler: ((error: ErrorType?) -> ())? = nil) throws {
		let socket = try self.getSocket()
		socket.emit(emitEvent)
		if let completionHandler = completionHandler {
			try self.listenForEvent(listenEvent, listenForValidationError: listenForValidationError, completionHandler: completionHandler)
		}
	}
	
	private func listenForEvent(event: String?, listenForValidationError: Bool = true, completionHandler: (error: ErrorType?) -> ()) throws {
		if event == nil || !listenForValidationError {
			dispatch_async(dispatch_get_main_queue()) {
				completionHandler(error: nil)
			}
			return
		}
		
		let socket = try self.getSocket()
		let uuid = NSUUID().UUIDString
		try self.lockHandlers {
			self.handlers[uuid] = completionHandler
		}
		
		if listenForValidationError {
			socket.on("validationError") { (data, ack) -> Void in
				do {
					if let handler = try self.handlerForUUID(uuid) {
						do {
							try self.lockHandlers {
								self.handlers.removeValueForKey(uuid)
							}
							let response = data.first as? [String: AnyObject]
							let details = response?["details"] as? [[String: AnyObject]]
							let message = details?.first?["message"] as? String
							handler(ErrorCode.ValidationError(message: message ?? "Unknown error"))
						} catch {
							handler(error)
						}
					}
				} catch {
					fatalError("Couldn't lock handlers: \(error)")
				}
			}
		}
		
		if let event = event {
			socket.on(event) { (data, ack) -> Void in
				do {
					if let handler = try self.handlerForUUID(uuid) {
						do {
							try self.lockHandlers {
								self.handlers.removeValueForKey(uuid)
							}
							handler(nil)
						} catch {
							handler(error)
						}
					}
				} catch {
					fatalError("Couldn't lock handlers: \(error)")
				}
			}
		}
	}
	
	private func cleanupHandlers() {
		for (_, handler) in self.handlers {
			handler(ErrorCode.Disconnected)
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
	
	private func handlerForUUID(uuid: String) throws -> ((ErrorType?) -> ())? {
		return try self.lockHandlers {
			return self.handlers[uuid]
		}
	}
}
