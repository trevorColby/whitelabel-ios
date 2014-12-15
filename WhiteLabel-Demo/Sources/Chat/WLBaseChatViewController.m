//
//  ChatViewController.m
//  WhiteLabel-Demo
//
//  Created by Ahuja on 20/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import "WLBaseChatViewController.h"
#import "WhiteLabel.h"
#import "WLChatMessage.h"
#import "WLDefaultChatTableViewCell.h"

@interface WLBaseChatViewController ()<UITableViewDataSource,
UITableViewDelegate,
UITextFieldDelegate>

@end

@implementation WLBaseChatViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  [self setUpNotificationListeners];
  [self setKeyboardNotifications];
  
  self.chatTableView.estimatedRowHeight = 44.0f;
  self.chatTableView.rowHeight = UITableViewAutomaticDimension;
  
  UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Disconnect"
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(disconnect:)];
  self.navigationItem.leftBarButtonItem = backButton;
  [self.sendMessageTextField becomeFirstResponder];
  [self.chatTableView reloadData];
  
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)setUpNotificationListeners {
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(newMessageReceived:)
                                               name:messageReceivedNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(userJoinedChat:)
                                               name:userJoinedChatNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(userLeftChat:)
                                               name:userLeftChatNotification
                                             object:nil];
}

- (void)disconnect: (id)sender {
  [[WhiteLabel sharedInstance] disconnectChatWithCompletionBlock:^(BOOL success, NSArray *result, NSError *error) {
  }];
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)newMessageReceived: (NSNotification*)notification {
  
  WLChatMessage *chatMessage = [notification userInfo][@"data"];
  [self reloadTableWithChatMessage:chatMessage];
  
}

- (void)userJoinedChat: (NSNotification*)notification {
  
  NSInteger userCount = [self.chat.userCount integerValue];
  self.chat.userCount = [NSNumber numberWithInteger:++userCount];
  
  WLChatMessage *chatMessage = [notification userInfo][@"data"];
  [self reloadTableWithChatMessage:chatMessage];
}

- (void)userLeftChat: (NSNotification*)notification {
  
  NSInteger userCount = [self.chat.userCount integerValue];
  self.chat.userCount = [NSNumber numberWithInteger:--userCount];
  
  WLChatMessage *chatMessage = [notification userInfo][@"data"];
  [self reloadTableWithChatMessage:chatMessage];
  
}

- (void)sendNewMessage: (NSString*)message {
  
  [[WhiteLabel sharedInstance] sendMessage:message
                       withCompletionBlock:^(BOOL success, NSArray *result, NSError *error) {
                         if (success) {
                           self.sendMessageTextField.text = @"";
                           NSString    *content = message;
                           WLChatMessage *chatMessage = [[WLChatMessage alloc] initWithMessageType:ChatMessageTypeMessage
                                                                                           content:content];
                           chatMessage.userName = self.username;
                           [self reloadTableWithChatMessage:chatMessage];
                         }
                       }];
}

- (void)reloadTableWithChatMessage:(WLChatMessage *)chatMessage {
  NSLog(@"just offset before: %f", self.chatTableView.contentOffset.y);

  [self.chat.messages addObject:chatMessage];
  
  [self.chatTableView beginUpdates];
  NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];
  [self.chatTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
  [self.chatTableView endUpdates];
  
  
//  [self.chatTableView reloadData];
  
//  [self.view layoutIfNeeded];
  
//  [self.chatTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(self.chat.messages.count-1) inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
//  
//  NSLog(@"index: %ld", self.chat.messages.count-1);
  
////  [self.view layoutIfNeeded];
//  
//  CGPoint newOffset = self.chatTableView.contentOffset;
//  
//  if ((self.chatTableView.contentSize.height) > self.chatTableView.frame.size.height) {
//    newOffset.y = self.chatTableView.contentSize.height - self.chatTableView.frame.size.height;
//  }
//
//  NSLog(@"contentSize: %f", self.chatTableView.contentSize.height + self.chatTableView.contentInset.top);
//  NSLog(@"frame: %@", [NSValue valueWithCGRect:self.chatTableView.frame]);
//  NSLog(@"offset before: %f", self.chatTableView.contentOffset.y);
//  
//  [UIView animateWithDuration:0.5 animations:^{
//    self.chatTableView.contentOffset = newOffset;
//  } completion:^(BOOL finished) {
//    NSLog(@"offset after: %f", self.chatTableView.contentOffset.y);
//  }];
}

#pragma mark Keyboard Notifications
- (void)setKeyboardNotifications{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWillHide:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
  [[NSNotificationCenter defaultCenter]addObserver:self
                                          selector:@selector(keyboardWillShow:)
                                              name:UIKeyboardWillShowNotification
                                            object:nil];
}

- (void)keyboardWillHide: (NSNotification*)notification{
  self.chatMessageViewBottomConstraint.constant = 0;
}

- (void)keyboardWillShow: (NSNotification*)notification{
  
  NSDictionary *userInfo = [notification userInfo];
  CGSize kbSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
  self.chatMessageViewBottomConstraint.constant = kbSize.height;
}

#pragma mark UITableView Datasource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
  return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.chat.messages.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  WLDefaultChatTableViewCell   *cell;
  WLChatMessage *chatMessage = [self.chat.messages objectAtIndex:indexPath.row];
  
  NSString  *displayMessage;
  switch (chatMessage.messageType) {
    case ChatMessageTypeInfo:
      displayMessage = [NSString stringWithFormat:@"%@ users in chat", self.chat.userCount];
      cell = [tableView dequeueReusableCellWithIdentifier:kChatInfoCellIndentifier];
      break;
    case ChatMessageTypeInfoUserJoined:
      displayMessage = [NSString stringWithFormat:@"%@ joined. %@ users in chat", chatMessage.userName, self.chat.userCount];
      cell = [tableView dequeueReusableCellWithIdentifier:kChatInfoCellIndentifier];
      break;
    case ChatMessageTypeInfoUserLeft:
      displayMessage = [NSString stringWithFormat:@"%@ left. %@ users in chat", chatMessage.userName, self.chat.userCount];
      cell = [tableView dequeueReusableCellWithIdentifier:kChatInfoCellIndentifier];
      break;
    case ChatMessageTypeMessage:
      displayMessage = [NSString stringWithFormat:@"%@: %@", chatMessage.userName, chatMessage.content];
      if ([chatMessage.userName isEqualToString: self.username]) {
        cell = [tableView dequeueReusableCellWithIdentifier:kChatMessageSendCellIndentifier];
      } else {
        cell = [tableView dequeueReusableCellWithIdentifier:kChatMessageReceiveCellIndentifier];
      }
    default:
      break;
  }
  cell.messageLabel.text = displayMessage;
  return cell;
}

#pragma mark UITextField Delegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  if (textField.text.length) {
    [self sendNewMessage:textField.text];
  }
  return NO;
}

@end
