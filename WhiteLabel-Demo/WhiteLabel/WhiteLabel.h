//
//  WhiteLabel.h
//  WhiteLabel-Demo
//
//  Created by Ahuja on 18/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import <Foundation/Foundation.h>
@class WLChatMessage;

extern NSString    *const messageReceivedNotification;
extern NSString    *const userJoinedChatNotification;
extern NSString    *const userLeftChatNotification;

typedef void (^WhiteLabelCompletionBlock)(BOOL success,
                                          NSArray *result,
                                          NSError*error);

@protocol WhiteLabelDelegate;

@interface WhiteLabel : NSObject

@property (nonatomic, assign) BOOL isConnected;
@property (nonatomic, weak) id<WhiteLabelDelegate> delegate;

+ (instancetype)sharedInstance;

/** Connects with the specified host
 @param host host to connect with
 @param block Completion block to be executed once connection is completed
 */
- (void)connectWithHost: (NSString*)host withAccessToken:(NSString *)accessToken withCompletionBlock: (WhiteLabelCompletionBlock)block;

/** Joins a new chat
 @param userId userIdentifier of the user
 @param block Completion block to be executed once user joins the chat
 */
- (void)joinChatRoom:(NSDictionary *)params withCompletionBlock: (WhiteLabelCompletionBlock)block;

- (void)leaveChatRoom:(NSDictionary *)params withCompletionBlock: (WhiteLabelCompletionBlock)block;

/** Send a chat message to all users
 @param message message to be sent
 @param block Completion block to be executed once message is sent
 */
- (void)sendMessage:(NSDictionary *)params withCompletionBlock: (WhiteLabelCompletionBlock)block;

/** Disconnect the session
 @param block Completion block to be executed once connection is disconnected
 */

- (void)disconnectChatWithCompletionBlock: (WhiteLabelCompletionBlock)block;

- (void)userStartedTyping:(NSDictionary *)params completionBlock: (WhiteLabelCompletionBlock)block;

- (void)userStoppedTyping:(NSDictionary *)params completionBlock: (WhiteLabelCompletionBlock)block;

@end

@protocol WhiteLabelDelegate <NSObject>

- (void)whiteLabel:(WhiteLabel *)whiteLabel userDidRecieveMessage:(WLChatMessage *)message;

- (void)whiteLabel:(WhiteLabel *)whiteLabel userDidJoinChat:(WLChatMessage *)message;

- (void)whiteLabel:(WhiteLabel *)whiteLabel userDidLeaveChat:(WLChatMessage *)message;

- (void)whiteLabel:(WhiteLabel *)whiteLabel userDidStartTypingMessage:(WLChatMessage *)message;

- (void)whiteLabel:(WhiteLabel *)whiteLabel userDidStopTypingMessage:(WLChatMessage *)message;

@end
