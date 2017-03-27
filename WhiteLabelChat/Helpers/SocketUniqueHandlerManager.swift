//
//  SocketUniqueHandlerManager.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/30/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import SocketIO

class SocketUniqueHandlerManager {
	fileprivate let socket: SocketIOClient
	
	fileprivate lazy var handlersLock = NSLock()
	typealias CompletionHandlerType = (_ uuid: UUID, _ data: [AnyObject]) -> Void
	fileprivate typealias HandlersType = [String: CompletionHandlerType]
	fileprivate typealias EventHandlersType = [String: HandlersType]
	fileprivate var handlers: EventHandlersType = [:]
	
	init(socket: SocketIOClient) {
		self.socket = socket
	}

	@discardableResult
	func on(_ event: String, handlerUUID: UUID = UUID(), completion: @escaping CompletionHandlerType) -> UUID {
		if var handlers = self.handlersForEvent(event) {
			handlers[handlerUUID.uuidString] = completion
			
			self.lockHandlers {
				self.handlers[event] = handlers
			}
		} else {
			self.lockHandlers {
				self.handlers[event] = [handlerUUID.uuidString: completion]
			}
			
			self.socket.on(event) { (data, ack) in
				if let handlers = self.handlersForEvent(event) {
					for (_, handler) in handlers {
						handler(handlerUUID, data as [AnyObject])
					}
				}
			}
		}
		return handlerUUID
	}
	
	func off(_ event: String, handlerUUID: UUID) {
		if var handlers = self.handlersForEvent(event) {
			handlers.removeValue(forKey: handlerUUID.uuidString)
			
			self.lockHandlers {
				self.handlers[event] = handlers
			}
			
			if handlers.isEmpty {
				self.socket.off(event)
			}
		}
	}
	
	func off(_ event: String, handlerUUIDs: UUID...) {
		for handlerUUID in handlerUUIDs {
			self.off(event, handlerUUID: handlerUUID)
		}
	}
	
	fileprivate func lockHandlers<T>(action: () throws -> T) rethrows -> T {
		self.handlersLock.lock()
		defer { self.handlersLock.unlock() }
		return try action()
	}
	
	fileprivate func handlersForEvent(_ event: String) -> HandlersType? {
		return self.lockHandlers {
			return self.handlers[event]
		}
	}
}
