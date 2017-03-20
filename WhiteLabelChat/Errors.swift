//
//  Errors.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

public enum ErrorCode: Error {
	case invalidResponseReceived
	case requestFailed
	case incompleteJSON
	case notConnected
	case impossibleToConnectToServer
	case disconnected
	case requiresUserPhoto
	case validationError(message: String)
	case cannotSendMessage(message: Message, innerError: Error)
	case messageAlreadySent
}

public enum MappingError: Error {
	case noFactoryMethod
}
