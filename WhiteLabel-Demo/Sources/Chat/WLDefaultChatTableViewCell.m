//
//  ChatTableViewCell.m
//  WhiteLabel-Demo
//
//  Created by Ahuja on 20/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import "WLDefaultChatTableViewCell.h"

@interface WLDefaultChatTableViewCell ()

@property (weak, nonatomic) IBOutlet UIView *containerView;

@end

@implementation WLDefaultChatTableViewCell

- (void)awakeFromNib {
  self.containerView.layer.cornerRadius = 5.0f;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
  [super setSelected:selected animated:animated];
  // Configure the view for the selected state
}

- (void)setupViews:(NSDictionary *)data {
  // to be implemented
}

@end
