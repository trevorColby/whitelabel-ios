//
//  WLUser.m
//  WhiteLabel-Demo
//
//  Created by Ahuja on 30/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import "WLUser.h"

@implementation WLUser

- (instancetype)initWithUsername:(NSString *)username userId:(NSString *)userId userAvatar:(NSString *)userAvatar {
  self = [super init];
  if (self) {
    self.userAvatar = userAvatar;
    self.userId = userId;
    self.username = username;
  }
  return self;
}

- (instancetype)init {
  return [self initWithUsername:nil
                         userId:nil
                     userAvatar:nil];
}

@end
