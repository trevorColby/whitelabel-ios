//
//  ChatTableViewCell.h
//  WhiteLabel-Demo
//
//  Created by Ahuja on 20/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLBaseChatTableViewCell.h"

#define kChatMessageSendCellIndentifier @"ChatMessageSendCellIdentifier"
#define kChatMessageReceiveCellIndentifier @"ChatMessageReceiveCellIdentifier"
#define kChatInfoCellIndentifier @"ChatInfoCellIdentifier"

@interface WLDefaultChatTableViewCell : WLBaseChatTableViewCell

@property (nonatomic, weak) IBOutlet UILabel  *messageLabel;
@property (nonatomic, weak) IBOutlet UILabel  *userNameLabel;
@property (nonatomic, weak) IBOutlet UILabel  *timeLabel;

@end
