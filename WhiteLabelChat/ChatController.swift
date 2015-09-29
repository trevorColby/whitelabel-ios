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
	
	let chatServerURL: NSURL
	
	public convenience override init() {
		guard let baseURL = Configuration.defaultBaseURL else {
			fatalError("ChatController(): baseURL is nil and Configuration.defaultBaseURL is nil, did you forget to set it to your base URL?")
		}
		self.init(chatServerURL: baseURL)
	}
	
	public init(chatServerURL: NSURL) {
		self.chatServerURL = chatServerURL
	}
	
	public func connectWithUser(user: User, completionHandler: ((error: ErrorType?) -> ())?) {
		guard let authToken = user.authToken else {
			fatalError("Given non-authenticated user \(user.username) to ChatController.connectWithUser()")
		}
		
		let socket = SocketIOClient(socketURL: "localhost:3000", opts: ["connectParams": ["token": authToken]])
		
		socket.on("connect") { data, ack in
			completionHandler?(error: nil)
		}
		socket.connect(timeoutAfter: 5) { () -> Void in
			socket.off("connect")
			completionHandler?(error: ErrorCode.ImpossibleToConnectToServer)
		}
		
		self.socketInternal = socket
	}
	
	public func disconnect() {
		(try? self.getSocket())?.disconnect()
	}
}
