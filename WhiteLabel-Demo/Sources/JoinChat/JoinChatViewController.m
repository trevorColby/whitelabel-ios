//
//  JoinChatViewController.m
//  WhiteLabel-Demo
//
//  Created by Ahuja on 18/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import "JoinChatViewController.h"
#import "WhiteLabel.h"
#import "ChatViewController.h"

NSString   *const    host =  @"http://chat-white-label.herokuapp.com/";

@interface JoinChatViewController ()<UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField    *usernameTextField;

@end

@implementation JoinChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [[WhiteLabel sharedInstance] connectWithHost:host
                             withCompletionBlock:^(BOOL success, NSArray *result, NSError *error) {
                                 
                             }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewChatWithInfo: (NSDictionary*)info {
    NSNumber    *userCount = [info valueForKey:@"numUsers"];
    ChatViewController  *chatVC = [self.storyboard instantiateViewControllerWithIdentifier:kChatViewControllerIdentifier];
    chatVC.userCount = userCount;
    chatVC.username = self.usernameTextField.text;
    [self.navigationController pushViewController:chatVC animated:YES];
}

- (void)joinChatWithUsername: (NSString*)username {
    [[WhiteLabel sharedInstance] joinChatWithUsername:username
                                  withCompletionBlock:^(BOOL success, NSArray *result, NSError *error) {
        if (success) {
            [self viewChatWithInfo:[result firstObject]];
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
