//
//  TestsConstants.swift
//  WhiteLabelChat
//
//  Created by Stephane Copin on 10/2/15.
//  Copyright © 2015 Fueled. All rights reserved.
//

import Foundation
@testable import WhiteLabelChat

let ServerURL = URL(string: "http://172.16.31.79:3000")!
let APICallTimeout: TimeInterval = 30.0

var currentUser: User!
var chatController = ChatController(chatServerURL: ServerURL)
