//
//  CustomChatViewController.m
//  WhiteLabel-Demo
//
//  Created by Ritesh-Gupta on 30/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import "CustomChatViewController.h"

@interface CustomChatViewController ()

@property (weak, nonatomic) IBOutlet UITableView *chatTableView;
@property (weak, nonatomic) IBOutlet UITextField *sendMessageTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *chatMessageViewBottomConstraint;

@end

@implementation CustomChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
