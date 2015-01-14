//
//  WLChat+Additions.m
//  WhiteLabel-Demo
//
//  Created by rhg-fueled on 14/01/15.
//  Copyright (c) 2015 Fueled. All rights reserved.
//

#import "WLChat+Additions.h"
#import "WLChatMessage+Additions.h"

@implementation WLChat (Additions)

- (instancetype)initWithDict:(NSDictionary *)response {
  WLChat *chat = [[WLChat alloc] initWithChatId:response[@"channel"]
                                      chatTitle:response[@"title"]
                                   chatMessages:[self messagesFromResponse:response]
                                       chatType:ChatTypeGroup
                                 chatUsersCount:response[@"numUsers"]];
  return chat;
}

- (NSArray *)messagesFromResponse:(NSDictionary *)response {
  NSMutableArray *messages = [NSMutableArray array];
  for (NSDictionary *aMessage in response[@"messages"]) {
    [messages addObject:[[WLChatMessage alloc] initWithDict:aMessage]];
  }
  return messages;
}

@end
