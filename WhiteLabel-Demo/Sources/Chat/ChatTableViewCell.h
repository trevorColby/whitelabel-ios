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

@interface ChatTableViewCell : WLBaseChatTableViewCell

@property (nonatomic, weak) IBOutlet UILabel  *messageLabel;

@end
