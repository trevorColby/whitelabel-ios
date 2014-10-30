//
//  WLBaseChatTableViewCell.m
//  WhiteLabel-Demo
//
//  Created by Ritesh-Gupta on 30/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import "WLBaseChatTableViewCell.h"

@implementation WLBaseChatTableViewCell

#pragma iOS Default Methods

- (void)awakeFromNib {
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
  [super setSelected:selected animated:animated];
}

#pragma mark - Setup Methods

- (void)setupViews:(NSDictionary *)data {
  // to be implemented by respective sub-class
}

@end
