//
//  ChatMessage.m
//  WhiteLabel-Demo
//
//  Created by Ahuja on 20/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import "WLChatMessage.h"

@implementation WLChatMessage

- (instancetype)initWithMessageType:(ChatMessageType)messageType
                               uuid:(NSString *)uuid
                            content:(NSString *)content
                               time:(NSString *)time
                          channelId:(NSString *)channelId
                               user:(WLUser *)user {
  self = [super init];
  if (self) {
    self.uuid = uuid;
    self.messageType = messageType;
    self.content = content;
    self.time = time;
    self.channelId = channelId;
    self.user = user;
  }
  return self;
}

- (instancetype)init {
  return [self initWithMessageType:ChatMessageTypeMessage
                              uuid:nil
                           content:nil
                              time:nil
                         channelId:nil
                              user:nil];;
}

@end
