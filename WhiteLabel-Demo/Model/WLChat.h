//
//  WLChat.h
//  WhiteLabel-Demo
//
//  Created by Ahuja on 30/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
  ChatTypePrivate = 0,
  ChatTypeGroup
}ChatType;

@interface WLChat : NSObject

@property (nonatomic, strong) NSString  *title;
@property (nonatomic, strong) NSMutableArray   *messages;
@property (nonatomic, assign) ChatType  chatType;
@property (nonatomic, strong) NSNumber  *userCount;

- (instancetype)initWithTitle: (NSString*)title chatType: (ChatType)chatType;

@end
