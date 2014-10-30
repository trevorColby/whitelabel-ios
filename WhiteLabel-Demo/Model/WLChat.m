//
//  WLChat.m
//  WhiteLabel-Demo
//
//  Created by Ahuja on 30/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import "WLChat.h"

@implementation WLChat

- (instancetype)initWithTitle: (NSString*)title chatType: (ChatType)chatType {
  self = [super init];
  if (self) {
    self.title = title;
    self.chatType = chatType;
  }
  return self;
}

- (instancetype)init {
  return [self initWithTitle:nil chatType:ChatTypePrivate];
}

@end
