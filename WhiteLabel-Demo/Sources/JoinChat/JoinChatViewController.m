//
//  JoinChatViewController.m
//  WhiteLabel-Demo
//
//  Created by Ahuja on 18/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import "JoinChatViewController.h"
#import "WhiteLabel.h"
#import "WLBaseChatViewController.h"
#import "CustomChatViewController.h"
#import "WLChat.h"
#import "WLUser.h"

NSString   *const    host =  @"http://chat-white-label.herokuapp.com/";

@interface JoinChatViewController ()<UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField    *usernameTextField;

@end

@implementation JoinChatViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [[WhiteLabel sharedInstance] connectWithHost:host
                           withCompletionBlock:^(BOOL success, NSArray *result, NSError *error) {
                             
                           }];
  // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
  
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)viewChat:(NSDictionary*)chatInfo {
  CustomChatViewController  *chatVC = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([CustomChatViewController class])];
  chatVC.username = self.usernameTextField.text;
  chatVC.chat = chatInfo[@"chat"];
  [self.navigationController pushViewController:chatVC animated:YES];
}

- (void)joinChatWithUsername: (NSString*)username {
  [[WhiteLabel sharedInstance] joinChatWithUsername:username
                                withCompletionBlock:^(BOOL success, NSArray *result, NSError *error) {
                                  if (success) {
                                    [self viewChat:[result firstObject]];
                                  }
                                }];
}
/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
  
  if (textField.text.length) {
    [self joinChatWithUsername:textField.text];
    [textField resignFirstResponder];
    return YES;
  }
  
  return NO;
}

@end
