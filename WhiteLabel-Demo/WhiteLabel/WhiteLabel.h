//
//  WhiteLabel.h
//  WhiteLabel-Demo
//
//  Created by Ahuja on 18/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void (^whiteLabelCompletionBlock)(BOOL success,
                                          NSArray *result,
                                          NSError*error);

@interface WhiteLabel : NSObject

@property (nonatomic, assign) BOOL isConnected;

/** Connects with the specified host
 @param host host to connect with
 @param block Completion block to be executed once connection is completed
 */
- (void)connectWithHost: (NSString*)host withCompletionBlock: (whiteLabelCompletionBlock)block;


@end
