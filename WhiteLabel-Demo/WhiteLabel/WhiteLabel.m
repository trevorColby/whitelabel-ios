//
//  WhiteLabel.m
//  WhiteLabel-Demo
//
//  Created by Ahuja on 18/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import "WhiteLabel.h"
#import "SIOSocket.h"
#import "WLChat+Additions.h"
#import "WLChatMessage+Additions.h"
#import "WLUser+Additions.h"

NSString    *const kEventAddUser = @"joinRoom";
NSString    *const kEventLogin = @"joinedRoom";
NSString    *const kEventLeaveMoot = @"leaveRoom";
NSString    *const kEventNewMessage = @"newMessage";
NSString    *const kEventUserJoined = @"userJoined";
NSString    *const kEventUserLeft = @"userLeft";
NSString    *const kEventUserStartedTyping = @"typing";
NSString    *const kEventUserStoppedTyping = @"stopTyping";
NSString    *const kEventError = @"validationError";
NSString    *const KEventJoinBatchRooms = @"batchJoinRoom";

NSString    *const messageReceivedNotification = @"messageReceivedNotification";
NSString    *const userJoinedChatNotification = @"userJoinedChatNotification";
NSString    *const userLeftChatNotification = @"userLeftChatNotification";
NSString    *const userStartedTypingNotification = @"userStartedTypingNotification";
NSString    *const userStoppedTypingNotification = @"userStoppedTypingNotification";
NSString    *const validationErrorReceivedNotification = @"validationErrorReceivedNotification";

static WhiteLabel *whiteLabel;

@interface WhiteLabel()

@property (nonatomic, strong) SIOSocket *socket;
@property (nonatomic, copy) WhiteLabelCompletionBlock loginEventBlock;

@end

@implementation WhiteLabel

+ (instancetype)sharedInstance {
  if (!whiteLabel) {
    whiteLabel = [[WhiteLabel alloc] initWithDefaultSettings];
  }
  return whiteLabel;
}

- (instancetype)initWithDefaultSettings {
  self = [super init];
  if (self) {
    _eventAddUser = kEventAddUser;
    _eventLogin = kEventLogin;
    _eventLeaveMoot = kEventLeaveMoot;
    _eventNewMessage = kEventNewMessage;
    _eventUserJoined = kEventUserJoined;
    _eventUserLeft = kEventUserLeft;
    _eventUserStartedTyping = kEventUserStartedTyping;
    _eventUserStoppedTyping = kEventUserStoppedTyping;
    _eventJoinBatchRoom = KEventJoinBatchRooms;
    _eventError = kEventError;
  }
  
  return self;
}

- (instancetype)init {
  return [self initWithDefaultSettings];
}

- (void)connectWithHost:(NSString *)host withAccessToken:(NSString *)accessToken withCompletionBlock:(WhiteLabelCompletionBlock)block {
  
  NSString *hostWithAccessToken = [NSString stringWithFormat:@"%@?token=%@", host, accessToken];
  [SIOSocket socketWithHost:hostWithAccessToken response:^(SIOSocket *socket) {
    self.socket = socket;
    
    __weak WhiteLabel *wealSelf = self;
    
    self.socket.onConnect = ^(){
      wealSelf.isConnected = YES;
    };
    
    self.socket.onDisconnect = ^(){
      wealSelf.isConnected = NO;
      if ([wealSelf.delegate respondsToSelector:@selector(whiteLabelConnectionStatusChanged:)]) {
        [wealSelf.delegate whiteLabelConnectionStatusChanged:wealSelf];
      }
    };
    
    self.socket.onError = ^(NSDictionary* dictionary){
      if (wealSelf.loginEventBlock) {
        wealSelf.loginEventBlock(NO, @[dictionary], nil);
      }
    };
    
    if (!self.isConnected) {
      [self addNewMessageListener];
      [self addUserJoinedListener];
      [self addUserLeftListener];
      [self userStartedTypingListener];
      [self userStoppedTypingListener];
      [self addUserLoggedInListener];
      [self errorReceivedListener];
    }
    
    block(YES, nil, nil);
  }];
}

- (void)leaveChatRoom:(NSDictionary *)params withCompletionBlock:(WhiteLabelCompletionBlock)block {
  if (self.isConnected) {
    [self.socket emit:self.eventLeaveMoot args:@[params]];
    block(YES, nil, nil);
  } else {
    block(NO, nil, nil);
  }
}

- (void)joinChatRoom:(NSDictionary *)params withCompletionBlock:(WhiteLabelCompletionBlock)block {
  self.loginEventBlock = block;
  [self.socket emit:self.eventAddUser args:@[params]];
}

- (void)disconnectChatWithCompletionBlock: (WhiteLabelCompletionBlock)block {
  self.isConnected = NO;
  [self.socket close];
  self.socket.onDisconnect = ^(){
    block(YES, nil, nil);
  };
}

- (void)joinBatchRooms: (NSDictionary*)params withCompletionBlock: (WhiteLabelCompletionBlock)block {
  if (self.isConnected) {
    [self.socket emit:self.eventJoinBatchRoom args:@[params]];
  }
  if (block) {
    block(self.isConnected, nil, nil);
  }
}

- (void)sendMessage:(NSDictionary *)params withCompletionBlock:(WhiteLabelCompletionBlock)block {
  if (self.isConnected) {
    [self.socket emit:self.eventNewMessage args:@[params]];
    block(YES, nil, nil);
  } else {
    block(NO, nil, nil);
  }
}

- (void)userStartedTyping:(NSDictionary *)params completionBlock:(WhiteLabelCompletionBlock)block {
  if (self.isConnected) {
    [self.socket emit:self.eventUserStartedTyping args:@[params]];
    block(YES, nil, nil);
  } else {
    block(NO, nil, nil);
  }
}

- (void)userStoppedTyping:(NSDictionary *)params completionBlock:(WhiteLabelCompletionBlock)block {
  if (self.isConnected) {
    [self.socket emit:self.eventUserStoppedTyping args:@[params]];
    block(YES, nil, nil);
  } else {
    block(NO, nil, nil);
  }
}

- (NSDictionary *)updateResponse:(id)data
                 chatMessageType:(ChatMessageType)chatMessageType {
  NSMutableDictionary *response = [NSMutableDictionary dictionaryWithDictionary:data[0]];
  [response setObject:[NSNumber numberWithInt:ChatMessageTypeMessage] forKey:@"chatType"];
  return response;
}

#pragma mark Socket Event Listeners
- (void)addUserLoggedInListener {
  [self.socket on:self.eventLogin callback:^(id data) {
    
    dispatch_async(dispatch_get_main_queue(), ^{
      NSDictionary *response = [self updateResponse:data
                                    chatMessageType:ChatMessageTypeMessage];
      NSArray *responseArray = [NSArray arrayWithObject:[[WLChat alloc] initWithDict:response]];
      if (self.loginEventBlock) {
        self.loginEventBlock(YES, responseArray, nil);
      }
      self.loginEventBlock = nil;
    });
  }];
}

- (void)addNewMessageListener {
  [self.socket on:self.eventNewMessage callback:^(id data) {
    
    dispatch_async(dispatch_get_main_queue(), ^{
      NSDictionary *response = [self updateResponse:data
                                    chatMessageType:ChatMessageTypeMessage];
      
      WLChatMessage *message = [[WLChatMessage alloc] initWithDict:response];
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
  [self.socket on:self.eventUserJoined callback:^(id data) {
    
    dispatch_async(dispatch_get_main_queue(), ^{
      NSDictionary *response = [self updateResponse:data
                                    chatMessageType:ChatMessageTypeInfoUserJoined];
      
      WLChatMessage *message = [[WLChatMessage alloc] initWithDict:response];
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
  [self.socket on:self.eventUserLeft callback:^(id data) {
    
    dispatch_async(dispatch_get_main_queue(), ^{
      NSDictionary *response = [self updateResponse:data
                                    chatMessageType:ChatMessageTypeInfoUserLeft];
      
      WLChatMessage *message = [[WLChatMessage alloc] initWithDict:response];
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
  [self.socket on:self.eventUserStartedTyping callback:^(id data) {
    
    dispatch_async(dispatch_get_main_queue(), ^{
      NSDictionary *response = [self updateResponse:data
                                    chatMessageType:ChatMessageTypeInfoUserStartedTyping];
      
      WLChatMessage *message = [[WLChatMessage alloc] initWithDict:response];
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
  [self.socket on:self.eventUserStoppedTyping callback:^(id data) {
    
    dispatch_async(dispatch_get_main_queue(), ^{
      NSDictionary *response = [self updateResponse:data
                                    chatMessageType:ChatMessageTypeInfoUserStoppedTyping];
      
      WLChatMessage *message = [[WLChatMessage alloc] initWithDict:response];
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

- (void)errorReceivedListener {
  [self.socket on:self.eventError callback:^(id data) {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.loginEventBlock) {
        NSString *errorString = [[[data firstObject] objectForKey:@"details"] valueForKey:@"message"];
        NSDictionary  *errorInfo = [NSDictionary dictionaryWithObject:errorString forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:@"White Label" code:401 userInfo:errorInfo];
        self.loginEventBlock(NO, nil, error);
        self.loginEventBlock = nil;
      }
    });
  }];
}

@end
