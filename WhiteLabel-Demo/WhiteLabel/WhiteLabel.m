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

NSString    *const kEventAddUser = @"joinChannel";
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
@property (nonatomic, copy) WhiteLabelCompletionBlock loginEventBlock;

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
      weakSelf.isConnected = YES;
    };
    weakSelf.socket.onDisconnect = ^(){
      weakSelf.isConnected = NO;
    };
    
    if (!weakSelf.isConnected) {
      [self addNewMessageListener];
      [self addUserJoinedListener];
      [self addUserLeftListener];
      [self userStartedTypingListener];
      [self userStoppedTypingListener];
      [self addUserLoggedInListener];
    }
    
    block(YES, nil, nil);
  }];
}

- (void)joinChatRoom:(NSDictionary *)params withCompletionBlock:(WhiteLabelCompletionBlock)block {
  self.loginEventBlock = block;
  [self.socket emit:kEventAddUser args:@[params]];
  self.socket.onError = ^(NSDictionary* data){
    block(NO, nil, nil);
  };
}

- (void)disconnectChatWithCompletionBlock: (WhiteLabelCompletionBlock)block {
  __weak WhiteLabel *weakSelf = self;
  
  [self.socket close];
  self.socket.onDisconnect = ^(){
    
    weakSelf.isConnected = NO;
    block(YES, nil, nil);
  };
}

- (void)sendMessage:(NSDictionary *)params withCompletionBlock:(WhiteLabelCompletionBlock)block {
  if (self.isConnected) {
    [self.socket emit:kEventNewMessage args:@[params]];
    block(YES, nil, nil);
  } else {
    block(NO, nil, nil);
  }
}

- (void)userStartedTyping:(NSDictionary *)params completionBlock:(WhiteLabelCompletionBlock)block {
  if (self.isConnected) {
    [self.socket emit:kEventUserStartedTyping args:@[params]];
    block(YES, nil, nil);
  } else {
    block(NO, nil, nil);
  }
}

- (void)userStoppedTyping:(NSDictionary *)params completionBlock:(WhiteLabelCompletionBlock)block {
  if (self.isConnected) {
    [self.socket emit:kEventUserStoppedTyping args:@[params]];
    block(YES, nil, nil);
  } else {
    block(NO, nil, nil);
  }
}

#pragma mark Socket Event Listeners
- (void)addUserLoggedInListener {
  [self.socket on:kEventLogin callback:^(id data) {
    NSArray *responseArray;
    
    if (data) {
      NSDictionary *response = data[0];
      
      WLChat *chat = [[WLChat alloc] init];
      chat.chatId = response[@"channel"];
      chat.chatUserCount = response[@"numUsers"];
      chat.chatMessages = [NSMutableArray array];
      
      for (NSDictionary *aMessage in response[@"messages"]) {
        WLChatMessage *chatMessage = [[WLChatMessage alloc] init];
        chatMessage.messageType = ChatMessageTypeInfoUserLoggedIn;
        chatMessage.content = aMessage[@"message"];
        chatMessage.userName = aMessage[@"username"];
        
        [chat.chatMessages addObject:chatMessage];
      }
      
      responseArray = [NSArray arrayWithObject:chat];
    }
    
    self.loginEventBlock(YES, responseArray, nil);
  }];
}

- (void)addNewMessageListener {
  NSLog(@"i am becoming the listener");
  [self.socket on:kEventNewMessage callback:^(id data) {
    dispatch_async(dispatch_get_main_queue(), ^{
      
      NSLog(@"new data new data");
      
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
