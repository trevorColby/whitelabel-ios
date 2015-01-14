//
//  WLChat.m
//  WhiteLabel-Demo
//
//  Created by Ahuja on 30/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import "WLChat.h"

@implementation WLChat

- (instancetype)initWithChatId:(NSString *)chatId
                     chatTitle:(NSString *)chatTitle
                  chatMessages:(NSArray *)chatMessages
                      chatType:(ChatType)chatType
                chatUsersCount:(NSNumber *)chatUsersCount {
  self = [super init];
  if (self) {
    self.chatId = chatId;
    self.chatMessages = chatMessages;
    self.chatTitle = chatTitle;
    self.chatType = chatType;
    self.chatUsersCount = chatUsersCount;
  }
  return self;
}

- (instancetype)init {
  return [self initWithChatId:nil
                    chatTitle:nil
                 chatMessages:nil
                     chatType:ChatTypeGroup
               chatUsersCount:nil];
}

@end
