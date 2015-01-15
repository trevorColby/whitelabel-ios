//
//  WLUser+Additions.m
//  WhiteLabel-Demo
//
//  Created by rhg-fueled on 14/01/15.
//  Copyright (c) 2015 Fueled. All rights reserved.
//

#import "WLUser+Additions.h"

@implementation WLUser (Additions)

- (instancetype)initWithDict:(NSDictionary *)response {
  WLUser *user = [[WLUser alloc] initWithUsername:response[@"username"]
                                           userId:response[@"userProfileId"]
                                       userAvatar:response[@"userPhoto"]];
  return user;
}

@end
