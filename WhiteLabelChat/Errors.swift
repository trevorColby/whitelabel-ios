//
//  Errors.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 9/29/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation

public enum ErrorCode: ErrorType {
	case InvalidResponseReceived
	case RequestFailed
	case IncompleteJSON
	case NotConnected
	case ImpossibleToConnectToServer
	case Disconnected
	case RequiresUserPhoto
	case ValidationError(message: String)
	case CannotSendMessage(message: Message, innerError: ErrorType)
	case MessageAlreadySent
}

public enum MappingError: ErrorType {
	case NoFactoryMethod
}
