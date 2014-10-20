//
//  ChatMessage.m
//  WhiteLabel-Demo
//
//  Created by Ahuja on 20/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import "ChatMessage.h"

@implementation ChatMessage

- (instancetype)initWithMessageType: (ChatMessageType)messageType content: (NSString*)content {
    self = [super init];
    if (self) {
        self.messageType = messageType;
        self.content = content;
    }
    return self;
}

- (instancetype)init {
    return [self initWithMessageType:ChatMessageTypeInfo content:nil];
}


@end
