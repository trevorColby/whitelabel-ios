//
//  WLUser.h
//  WhiteLabel-Demo
//
//  Created by Ahuja on 30/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLUser : NSObject

@property (nonatomic, strong) NSString  *username;
@property (nonatomic, strong) NSString  *userId;
@property (nonatomic, strong) NSString  *userAvatar;

- (instancetype)initWithUsername:(NSString *)username
                          userId:(NSString *)userId
                      userAvatar:(NSString *)userAvatar;

@end
