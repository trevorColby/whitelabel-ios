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
NSString    *const kEventUserStartedTyping = @"userStartedTyping";
NSString    *const kEventUserStoppedTyping = @"userStoppedTyping";

NSString    *const messageReceivedNotification = @"messageReceivedNotification";
NSString    *const userJoinedChatNotification = @"userJoinedChatNotification";
NSString    *const userLeftChatNotification = @"userLeftChatNotification";
NSString    *const userStartedTypingNotification = @"userStartedTypingNotification";
NSString    *const userStoppedTypingNotification = @"userStoppedTypingNotification";

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

- (void)connectWithHost:(NSString *)host withAccessToken:(NSString *)accessToken withCompletionBlock:(WhiteLabelCompletionBlock)block {
  
  NSString *hostWithAccessToken = [NSString stringWithFormat:@"%@?token=%@", host, accessToken];
  
  [SIOSocket socketWithHost:hostWithAccessToken response:^(SIOSocket *socket) {
    self.socket = socket;
    __weak WhiteLabel *weakSelf = self;
    weakSelf.socket.onConnect = ^(){
      NSLog(@"i'm connected");
      weakSelf.isConnected = YES;
      [weakSelf addNewMessageListener];
      [weakSelf addUserJoinedListener];
      [weakSelf addUserLeftListener];
      [weakSelf userStartedTypingListener];
      [weakSelf userStoppedTypingListener];
      block(YES, nil, nil);
    };
    self.socket.onDisconnect = ^(){
      weakSelf.isConnected = NO;
    };
  }];
}

- (void)joinChatRoom:(NSString *)chatRoomId withCompletionBlock:(WhiteLabelCompletionBlock)block {
  [self.socket emit:kEventAddUser args:@[chatRoomId]];
  [self.socket on:kEventLogin callback:^(NSArray *args) {
    block(YES, nil, nil);
  }];
  self.socket.onError = ^(NSDictionary* data){
    NSLog(@"join chat room error: %@", data);
    block(NO, nil, nil);
  };
}

- (void)disconnectChatWithCompletionBlock: (WhiteLabelCompletionBlock)block {
  [self.socket close];
  self.socket.onDisconnect = ^(){
    block(YES, nil, nil);
  };
}

- (void)sendMessage: (NSString*)message withCompletionBlock: (WhiteLabelCompletionBlock)block {
  [self.socket emit:kEventNewMessage args:@[message]];
  [self.socket on:kEventNewMessage callback:^(NSArray *args) {
    block(YES, nil, nil);
  }];
  self.socket.onError = ^(NSDictionary* data){
    NSLog(@"send message error: %@", data);
    block(NO, nil, nil);
  };
}

- (void)userStartedTypingWithCompletionBlock:(WhiteLabelCompletionBlock)block {
  [self.socket emit:kEventUserStartedTyping];
  [self.socket on:kEventUserStartedTyping callback:^(NSArray *args) {
    block(YES, nil, nil);
  }];
  self.socket.onError = ^(NSDictionary* data){
    NSLog(@"user started typing error: %@", data);
    block(NO, nil, nil);
  };
}

- (void)userStoppedTypingWithCompletionBlock:(WhiteLabelCompletionBlock)block {
  [self.socket emit:kEventUserStoppedTyping];
  [self.socket on:kEventUserStoppedTyping callback:^(NSArray *args) {
    block(YES, nil, nil);
  }];
  self.socket.onError = ^(NSDictionary* data){
    NSLog(@"user stopped typing error: %@", data);
    block(NO, nil, nil);
  };
}

#pragma mark Socket Event Listeners
- (void)addNewMessageListener {
  
  [self.socket on:kEventNewMessage callback:^(id data) {
    dispatch_async(dispatch_get_main_queue(), ^{
      
      WLChatMessage *message = [WLChatMessage new];
      message.messageType = ChatMessageTypeMessage;
      message.content = [data firstObject][@"message"];
      message.userName = [data firstObject][@"username"];
      
      if ([self.delegate respondsToSelector:@selector(whiteLabel:userDidRecieveMessage:)]) {
        [self.delegate whiteLabel:self userDidRecieveMessage:message];

      } else {
        NSDictionary  *data = [NSDictionary dictionaryWithObject:message forKey:@"data"];
        [[NSNotificationCenter defaultCenter] postNotificationName:messageReceivedNotification
                                                            object:nil
                                                          userInfo:data];
      }
      
    });
  }];
}

- (void)addUserJoinedListener {
  
  [self.socket on:kEventUserJoined callback:^(id data) {
    dispatch_async(dispatch_get_main_queue(), ^{
      
      WLChatMessage *message = [WLChatMessage new];
      message.messageType = ChatMessageTypeInfoUserJoined;
      message.userName = [data firstObject][@"username"];
      
      if ([self.delegate respondsToSelector:@selector(whiteLabel:userDidJoinChat:)]) {
        [self.delegate whiteLabel:self userDidJoinChat:message];

      } else {
        NSDictionary  *data = [NSDictionary dictionaryWithObject:message forKey:@"data"];
        [[NSNotificationCenter defaultCenter] postNotificationName:userJoinedChatNotification
                                                            object:nil
                                                          userInfo:data];
      }

    });
  }];
}

- (void)addUserLeftListener {
  
  [self.socket on:kEventUserLeft callback:^(id data) {
    
    dispatch_async(dispatch_get_main_queue(), ^{
      
      WLChatMessage *message = [WLChatMessage new];
      message.messageType = ChatMessageTypeInfoUserLeft;
      message.userName = [data firstObject][@"username"];

      if ([self.delegate respondsToSelector:@selector(whiteLabel:userDidLeaveChat:)]) {
        [self.delegate whiteLabel:self userDidLeaveChat:message];

      } else {
        NSDictionary  *data = [NSDictionary dictionaryWithObject:message forKey:@"data"];
        [[NSNotificationCenter defaultCenter] postNotificationName:userLeftChatNotification
                                                            object:nil
                                                          userInfo:data];
      }
    });
  }];
}

- (void)userStartedTypingListener {
  [self.socket on:kEventUserStartedTyping callback:^(id data) {
    dispatch_async(dispatch_get_main_queue(), ^{
      
      WLChatMessage *message = [WLChatMessage new];
      message.messageType = ChatMessageTypeInfoUserStartedTyping;
      message.userName = [data firstObject][@"username"];
      
      if ([self.delegate respondsToSelector:@selector(whiteLabel:userDidStartTypingMessage:)]) {
        [self.delegate whiteLabel:self userDidStartTypingMessage:message];
 
      } else {
        NSDictionary  *data = [NSDictionary dictionaryWithObject:message forKey:@"data"];
        [[NSNotificationCenter defaultCenter] postNotificationName:userStartedTypingNotification
                                                            object:nil
                                                          userInfo:data];
      }
    });
  }];
}

- (void)userStoppedTypingListener {
  [self.socket on:kEventUserStoppedTyping callback:^(id data) {
    dispatch_async(dispatch_get_main_queue(), ^{
      
      WLChatMessage *message = [WLChatMessage new];
      message.messageType = ChatMessageTypeInfoUserStoppedTyping;
      message.userName = [data firstObject][@"username"];
      
      if ([self.delegate respondsToSelector:@selector(whiteLabel:userDidStopTypingMessage:)]) {
        [self.delegate whiteLabel:self userDidStopTypingMessage:message];

      } else {
        NSDictionary  *data = [NSDictionary dictionaryWithObject:message forKey:@"data"];
        [[NSNotificationCenter defaultCenter] postNotificationName:userStoppedTypingNotification
                                                            object:nil
                                                          userInfo:data];
      }
    });
  }];
}

@end
