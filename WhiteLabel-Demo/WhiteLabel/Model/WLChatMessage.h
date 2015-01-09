//
//  ChatMessage.h
//  WhiteLabel-Demo
//
//  Created by Ahuja on 20/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLUser.h"

typedef enum {
    ChatMessageTypeInfo = 0,
    ChatMessageTypeInfoUserLoggedIn,
    ChatMessageTypeInfoUserJoined,
    ChatMessageTypeInfoUserLeft,
    ChatMessageTypeInfoUserStartedTyping,
    ChatMessageTypeInfoUserStoppedTyping,
    ChatMessageTypeMessage
}ChatMessageType;

@interface WLChatMessage : NSObject

@property (nonatomic, assign) ChatMessageType   messageType;
@property (nonatomic, strong) NSString  *content;
@property (nonatomic, strong) NSDate  *time;
@property (nonatomic, strong) NSString  *userName;
@property (nonatomic, strong) NSString  *userId;
@property (nonatomic, strong) NSString  *userAvatar;

- (instancetype)initWithMessageType: (ChatMessageType)messageType content: (NSString*)content;

@end
