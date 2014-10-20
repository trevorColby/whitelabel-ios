//
//  WhiteLabel.h
//  WhiteLabel-Demo
//
//  Created by Ahuja on 18/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString    *const messageReceivedNotification;
extern NSString    *const userJoinedChatNotification;
extern NSString    *const userLeftChatNotification;

typedef void (^whiteLabelCompletionBlock)(BOOL success,
                                          NSArray *result,
                                          NSError*error);

@interface WhiteLabel : NSObject

@property (nonatomic, assign) BOOL isConnected;

+ (instancetype)sharedInstance;

/** Connects with the specified host
 @param host host to connect with
 @param block Completion block to be executed once connection is completed
 */
- (void)connectWithHost: (NSString*)host withCompletionBlock: (whiteLabelCompletionBlock)block;

/** Joins a new chat
 @param username username of the user
 @param block Completion block to be executed once user joins the chat
 */
- (void)joinChatWithUsername: (NSString*)username withCompletionBlock: (whiteLabelCompletionBlock)block;

- (void)sendMessage: (NSString*)message withCompletionBlock: (whiteLabelCompletionBlock)block;


@end
