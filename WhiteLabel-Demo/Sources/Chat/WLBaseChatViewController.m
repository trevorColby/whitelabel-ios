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
  
  NSInteger userCount = [self.chat.chatUsersCount integerValue];
  self.chat.chatUsersCount = [NSNumber numberWithInteger:++userCount];
  
  WLChatMessage *chatMessage = [notification userInfo][@"data"];
  [self reloadTableWithChatMessage:chatMessage];
}

- (void)userLeftChat: (NSNotification*)notification {
  
  NSInteger userCount = [self.chat.chatUsersCount integerValue];
  self.chat.chatUsersCount = [NSNumber numberWithInteger:--userCount];
  
  WLChatMessage *chatMessage = [notification userInfo][@"data"];
  [self reloadTableWithChatMessage:chatMessage];
  
}

- (void)sendNewMessage: (NSString*)message {
//  [[WhiteLabel sharedInstance] sendMessage:message
//                       withCompletionBlock:^(BOOL success, NSArray *result, NSError *error) {
//                         if (success) {
//                           self.sendMessageTextField.text = @"";
//                           NSString    *content = message;
//                           WLChatMessage *chatMessage = [[WLChatMessage alloc] initWithMessageType:ChatMessageTypeMessage
//                                                                                           content:content];
//                           chatMessage.userName = self.username;
//                           [self reloadTableWithChatMessage:chatMessage];
//                         }
//                       }];
}

- (void)reloadTableWithChatMessage:(WLChatMessage *)chatMessage {
//  [self.chat.chatMessages addObject:chatMessage];
  NSArray *indexPaths = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]];

  [self.chatTableView beginUpdates];
  [self.chatTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
  [self.chatTableView endUpdates];
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
  return self.chat.chatMessages.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  WLDefaultChatTableViewCell   *cell;
//  WLChatMessage *chatMessage = [self.chat.chatMessages objectAtIndex:indexPath.row];
//
//  NSString  *displayMessage;
//  switch (chatMessage.messageType) {
//    case ChatMessageTypeInfo:
//      displayMessage = [NSString stringWithFormat:@"%@ users in chat", self.chat.chatUsersCount];
//      cell = [tableView dequeueReusableCellWithIdentifier:kChatInfoCellIndentifier];
//      break;
//    case ChatMessageTypeInfoUserJoined:
//      displayMessage = [NSString stringWithFormat:@"%@ joined. %@ users in chat", chatMessage.userName, self.chat.chatUserCount];
//      cell = [tableView dequeueReusableCellWithIdentifier:kChatInfoCellIndentifier];
//      break;
//    case ChatMessageTypeInfoUserLeft:
//      displayMessage = [NSString stringWithFormat:@"%@ left. %@ users in chat", chatMessage.userName, self.chat.chatUserCount];
//      cell = [tableView dequeueReusableCellWithIdentifier:kChatInfoCellIndentifier];
//      break;
//    case ChatMessageTypeMessage:
//      displayMessage = [NSString stringWithFormat:@"%@: %@", chatMessage.userName, chatMessage.content];
//      if ([chatMessage.userName isEqualToString: self.username]) {
//        cell = [tableView dequeueReusableCellWithIdentifier:kChatMessageSendCellIndentifier];
//      } else {
//        cell = [tableView dequeueReusableCellWithIdentifier:kChatMessageReceiveCellIndentifier];
//      }
//    default:
//      break;
//  }
//  cell.messageLabel.text = displayMessage;
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
