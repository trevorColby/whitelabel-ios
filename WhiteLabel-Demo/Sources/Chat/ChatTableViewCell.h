//
//  ChatTableViewCell.h
//  WhiteLabel-Demo
//
//  Created by Ahuja on 20/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kChatMessageCellIndentifier @"ChatMessageCellIdentifier"
#define kChatInfoCellIndentifier @"ChatInfoCellIdentifier"

@interface ChatTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel  *messageLabel;

@end
