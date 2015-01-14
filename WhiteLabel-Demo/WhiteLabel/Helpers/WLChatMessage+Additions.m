//
//  WLChatMessage+Additions.m
//  WhiteLabel-Demo
//
//  Created by rhg-fueled on 14/01/15.
//  Copyright (c) 2015 Fueled. All rights reserved.
//

#import "WLChatMessage+Additions.h"
#import "WLUser+Additions.h"

@implementation WLChatMessage (Additions)

- (instancetype)initWithDict:(NSDictionary *)response {
  NSNumber *chatType = response[@"chatType"];

  WLUser *user = [[WLUser alloc] initWithDict:response];
  WLChatMessage *chatMessage = [[WLChatMessage alloc] initWithMessageType:chatType.intValue
                                                                  content:response[@"message"]
                                                                     time:response[@"created"]
                                                                channelId:response[@"channel"]
                                                                     user:user];
  return chatMessage;
}

@end
