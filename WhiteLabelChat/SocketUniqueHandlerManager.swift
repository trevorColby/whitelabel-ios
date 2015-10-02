//
//  SocketUniqueHandlerManager.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/30/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import SocketIO

class SocketUniqueHandlerManager {
	private let socket: SocketIOClient
	
	private lazy var handlersLock = NSLock()
	typealias CompletionHandlerType = (uuid: NSUUID, data: [AnyObject]) -> Void
	private typealias HandlersType = [String: CompletionHandlerType]
	private typealias EventHandlersType = [String: HandlersType]
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
	
	func off(event: String, handlerUUIDs: NSUUID...) {
		for handlerUUID in handlerUUIDs {
			self.off(event, handlerUUID: handlerUUID)
		}
	}
	
	private func lockHandlers<T>(action: () throws -> T) rethrows -> T {
		self.handlersLock.lock()
		defer { self.handlersLock.unlock() }
		return try action()
	}
	
	private func handlersForEvent(event: String) -> HandlersType? {
		return self.lockHandlers {
			return self.handlers[event]
		}
	}
}
