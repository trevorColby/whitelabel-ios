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

@property (nonatomic, strong) NSString  *chatId;
@property (nonatomic, strong) NSString  *chatTitle;
@property (nonatomic, strong) NSArray   *chatMessages;
@property (nonatomic, assign) ChatType  chatType;
@property (nonatomic, strong) NSNumber  *chatUsersCount;

- (instancetype)initWithChatId:(NSString *)chatId
                     chatTitle:(NSString *)chatTitle
                  chatMessages:(NSArray *)chatMessages
                      chatType:(ChatType)chatType
                chatUsersCount:(NSNumber *)chatUsersCount;

@end
