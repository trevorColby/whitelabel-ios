//
//  WhiteLabel.m
//  WhiteLabel-Demo
//
//  Created by Ahuja on 18/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import "WhiteLabel.h"
#import "SIOSocket.h"
#import "WLChat.h"
#import "WLChatMessage.h"
#import "WLUser.h"

NSString    *const kEventAddUser = @"addUser";
NSString    *const kEventLogin = @"login";
NSString    *const kEventNewMessage = @"newMessage";
NSString    *const kEventUserJoined = @"userJoined";
NSString    *const kEventUserLeft = @"userLeft";

NSString    *const messageReceivedNotification = @"messageReceivedNotification";
NSString    *const userJoinedChatNotification = @"userJoinedChatNotification";
NSString    *const userLeftChatNotification = @"userLeftChatNotification";

static WhiteLabel *whiteLabel;

@interface WhiteLabel()

@property (nonatomic, strong) SIOSocket *socket;

@end

@implementation WhiteLabel

+ (instancetype)sharedInstance {
  if (!whiteLabel) {
    whiteLabel = [[WhiteLabel alloc] init];
  }
  return whiteLabel;
}

- (void)connectWithHost:(NSString *)host withCompletionBlock:(whiteLabelCompletionBlock)block {
  [SIOSocket socketWithHost:host response:^(SIOSocket *socket) {
    self.socket = socket;
    __weak WhiteLabel *weakSelf = self;
    weakSelf.socket.onConnect = ^(){
      NSLog(@"i'm connected");
      weakSelf.isConnected = YES;
      [weakSelf addNewMessageListener];
      [weakSelf addUserJoinedListener];
      [weakSelf addUserLeftListener];

    };
    self.socket.onDisconnect = ^(){
      weakSelf.isConnected = NO;
    };
  }];
}

- (void)joinChatWithUsername: (NSString*)username withCompletionBlock: (whiteLabelCompletionBlock)block {
  
  [self.socket on:kEventLogin callback:^(id data) {
    dispatch_async(dispatch_get_main_queue(), ^{

      WLChatMessage *chatMessage = [[WLChatMessage alloc] initWithMessageType:ChatMessageTypeInfo
                                                                      content:nil];
      
      WLChat  *chat = [[WLChat alloc] init];
      chat.title = @"White Label Chat";
      chat.userCount = [data firstObject][@"numUsers"];
      chat.messages = [NSMutableArray arrayWithObject:chatMessage];
      
      WLUser  *user = [[WLUser alloc] init];
      user.username = username;

      NSDictionary  *data = [NSDictionary dictionaryWithObjectsAndKeys:chat, @"chat",
                             user, @"user", nil];
      block(YES, @[data], nil);
    });
  }];
  
  self.socket.onError = ^(NSDictionary* data){
    NSLog(@"error: %@", data);
  };
  
  [self.socket emit:kEventAddUser args:@[username]];
}

- (void)disconnectChatWithCompletionBlock: (whiteLabelCompletionBlock)block {
  [self.socket close];
  block(YES, nil, nil);
}

- (void)sendMessage: (NSString*)message withCompletionBlock: (whiteLabelCompletionBlock)block {
  [self.socket emit:kEventNewMessage args:@[message]];
  block(YES, nil, nil);
}

#pragma mark Socket Event Listeners
- (void)addNewMessageListener {
  
  [self.socket on:kEventNewMessage callback:^(id data) {
    dispatch_async(dispatch_get_main_queue(), ^{
      
      WLChatMessage *message = [WLChatMessage new];
      message.messageType = ChatMessageTypeMessage;
      message.content = [data firstObject][@"message"];
      message.userName = [data firstObject][@"username"];
      
      NSDictionary  *data = [NSDictionary dictionaryWithObject:message forKey:@"data"];
      [[NSNotificationCenter defaultCenter] postNotificationName:messageReceivedNotification
                                                          object:nil
                                                        userInfo:data];
    });
  }];
}

- (void)addUserJoinedListener {
  
  [self.socket on:kEventUserJoined callback:^(id data) {
    dispatch_async(dispatch_get_main_queue(), ^{
      
      WLChatMessage *message = [WLChatMessage new];
      message.messageType = ChatMessageTypeInfoUserJoined;
      message.userName = [data firstObject][@"username"];
      
      NSDictionary  *data = [NSDictionary dictionaryWithObject:message forKey:@"data"];
      [[NSNotificationCenter defaultCenter] postNotificationName:userJoinedChatNotification
                                                          object:nil
                                                        userInfo:data];
    });
  }];
}

- (void)addUserLeftListener {
  
  [self.socket on:kEventUserLeft callback:^(id data) {
    
    dispatch_async(dispatch_get_main_queue(), ^{
      
      WLChatMessage *message = [WLChatMessage new];
      message.messageType = ChatMessageTypeInfoUserLeft;
      message.userName = [data firstObject][@"username"];
      
      NSDictionary  *data = [NSDictionary dictionaryWithObject:message forKey:@"data"];
      [[NSNotificationCenter defaultCenter] postNotificationName:userLeftChatNotification
                                                          object:nil
                                                        userInfo:data];
    });
  }];
}

@end
