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

@property (nonatomic, strong) NSString  *uuid;
@property (nonatomic, strong) NSString  *content;
@property (nonatomic, strong) NSString  *time;
@property (nonatomic, strong) NSString  *channelId;
@property (nonatomic, assign) ChatMessageType   messageType;
@property (nonatomic, strong) WLUser *user;

- (instancetype)initWithMessageType: (ChatMessageType)messageType
                               uuid: (NSString*)uuid
                            content: (NSString*)content
                               time: (NSString *)time
                          channelId: (NSString *)channelId
                               user: (WLUser *)user;

@end
