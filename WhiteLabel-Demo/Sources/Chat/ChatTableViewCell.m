//
//  ChatTableViewCell.m
//  WhiteLabel-Demo
//
//  Created by Ahuja on 20/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import "ChatTableViewCell.h"

@interface ChatTableViewCell ()

@property (nonatomic, weak) IBOutlet UILabel  *userNameLabel;
@property (nonatomic, weak) IBOutlet UILabel  *timeLabel;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@end

@implementation ChatTableViewCell

- (void)awakeFromNib {
  self.containerView.layer.borderWidth = 1.0f;
  self.containerView.layer.borderColor = [UIColor blackColor].CGColor;
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
