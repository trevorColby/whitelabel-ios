//
//  ChatMessage.h
//  WhiteLabel-Demo
//
//  Created by Ahuja on 20/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ChatMessageTypeInfo = 0,
    ChatMessageTypeMessage
}ChatMessageType;

@interface WLChatMessage : NSObject

@property (nonatomic, assign) ChatMessageType   messageType;
@property (nonatomic, strong) NSString  *content;

- (instancetype)initWithMessageType: (ChatMessageType)messageType content: (NSString*)content;

@end
