//
//  ChatViewController.h
//  WhiteLabel-Demo
//
//  Created by Ahuja on 20/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLChat.h"

#define kChatViewControllerIdentifier @"ChatViewControllerIdentifier"

@interface WLBaseChatViewController : UIViewController

@property (nonatomic, strong) NSString  *username;
@property (nonatomic, strong) WLChat    *chat;
@property (nonatomic, weak) UITableView    *chatTableView;
@property (nonatomic, weak)  NSLayoutConstraint   *chatMessageViewBottomConstraint;
@property (nonatomic, weak)  UITextField    *sendMessageTextField;

@end
