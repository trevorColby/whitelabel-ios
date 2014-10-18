//
//  WhiteLabel.m
//  WhiteLabel-Demo
//
//  Created by Ahuja on 18/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import "WhiteLabel.h"
#import "SIOSocket.h"

static WhiteLabel *whiteLabel;

@interface WhiteLabel()

@property (nonatomic, strong) SIOSocket *socket;

@end

@implementation WhiteLabel

+ (instancetype)sharedInstane {
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
            block(YES, nil, nil);
        };
    }];
}

@end
