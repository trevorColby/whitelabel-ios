//
//  WhiteLabel.m
//  WhiteLabel-Demo
//
//  Created by Ahuja on 18/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import "WhiteLabel.h"
#import "SIOSocket.h"

NSString    *const kAddUser = @"addUser";
NSString    *const kLogin = @"login";

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
        self.socket.onConnect = ^(){
            weakSelf.isConnected = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf addNewMessageListener];
                [weakSelf addUserJoinedListener];
                [weakSelf addUserLeftListener];
                block(YES, nil, nil);
            });
        };
        self.socket.onDisconnect = ^(){
            weakSelf.isConnected = NO;
        };
    }];
}

- (void)joinChatWithUsername: (NSString*)username withCompletionBlock: (whiteLabelCompletionBlock)block {
    [self.socket emit:kAddUser, username, nil];
    [self.socket on:kLogin callback:^(id data) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block(YES, @[data], nil);
        });
    }];
}

- (void)disconnectChatWithCompletionBlock: (whiteLabelCompletionBlock)block {
    [self.socket close];
    block(YES, nil, nil);
}

- (void)sendMessage: (NSString*)message withCompletionBlock: (whiteLabelCompletionBlock)block {
    [self.socket emit:@"newMessage", message, ^() {
    }, nil];
    block(YES, nil, nil);
}

- (void)addNewMessageListener {
    [self.socket on:@"newMessage" callback:^(id data) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:messageReceivedNotification
                                                                object:nil
                                                              userInfo:data];
        });
    }];
}

- (void)addUserJoinedListener {
    [self.socket on:@"userJoined" callback:^(id data) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:userJoinedChatNotification
                                                                object:nil
                                                              userInfo:data];
        });
    }];
}

- (void)addUserLeftListener {
    [self.socket on:@"userLeft" callback:^(id data) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:userLeftChatNotification
                                                                object:nil
                                                              userInfo:data];
        });
    }];
}

@end
