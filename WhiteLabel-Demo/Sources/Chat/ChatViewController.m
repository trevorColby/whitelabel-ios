//
//  ChatViewController.m
//  WhiteLabel-Demo
//
//  Created by Ahuja on 20/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import "ChatViewController.h"
#import "WhiteLabel.h"
#import "WLChatMessage.h"
#import "ChatTableViewCell.h"

@interface ChatViewController ()<UITableViewDataSource,
UITableViewDelegate,
UITextFieldDelegate>

@property (nonatomic, strong) NSMutableArray    *chatMessages;
@property (nonatomic, weak) IBOutlet UITableView    *chatTableView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint   *chatMessageViewBottomConstraint;
@property (nonatomic, weak) IBOutlet UITextField    *sendMessageTextField;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setUpNotificationListeners];
    [self initializeChat];
    [self setKeyboardNotifications];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Disconnect"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(disconnect:)];
    self.navigationItem.leftBarButtonItem = backButton;
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

- (void)initializeChat {
    
    self.chatTableView.estimatedRowHeight = 44.0f;
    self.chatTableView.rowHeight = UITableViewAutomaticDimension;
    
    NSString    *content = [NSString stringWithFormat:@"%@ users in chat", self.userCount];
    WLChatMessage *chatMessage = [[WLChatMessage alloc] initWithMessageType:ChatMessageTypeInfo
                                                                content:content];
    self.chatMessages = [NSMutableArray arrayWithObject:chatMessage];
    [self.chatTableView reloadData];
}

- (void)newMessageReceived: (NSNotification*)notification {
    
    NSString    *userName = notification.userInfo[@"username"];
    NSString    *message = notification.userInfo[@"message"];
    NSString    *content = [NSString stringWithFormat:@"%@ : %@", userName, message];
    WLChatMessage *chatMessage = [[WLChatMessage alloc] initWithMessageType:ChatMessageTypeMessage
                                                                content:content];
    [self.chatMessages addObject:chatMessage];
    [self.chatTableView reloadData];
    
}

- (void)userJoinedChat: (NSNotification*)notification {
    
    NSString    *numUsers = notification.userInfo[@"numUsers"];
    NSString    *username = notification.userInfo[@"username"];
    NSString    *content = [NSString stringWithFormat:@"%@ joined. %@ users in chat", username, numUsers];
    WLChatMessage *chatMessage = [[WLChatMessage alloc] initWithMessageType:ChatMessageTypeInfo
                                                                content:content];
    [self.chatMessages addObject:chatMessage];
    [self.chatTableView reloadData];
}

- (void)userLeftChat: (NSNotification*)notification {
    NSString    *numUsers = notification.userInfo[@"numUsers"];
    NSString    *username = notification.userInfo[@"username"];
    NSString    *content = [NSString stringWithFormat:@"%@ left. %@ users in chat", username, numUsers];
    WLChatMessage *chatMessage = [[WLChatMessage alloc] initWithMessageType:ChatMessageTypeInfo
                                                                content:content];
    [self.chatMessages addObject:chatMessage];
    [self.chatTableView reloadData];
}

- (void)sendNewMessage: (NSString*)message {
    [[WhiteLabel sharedInstance] sendMessage:message
                         withCompletionBlock:^(BOOL success, NSArray *result, NSError *error) {
                             if (success) {
                                 self.sendMessageTextField.text = @"";
                                 NSString    *content = [NSString stringWithFormat:@"%@ : %@", self.username, message];
                                 WLChatMessage *chatMessage = [[WLChatMessage alloc] initWithMessageType:ChatMessageTypeMessage
                                                                                             content:content];
                                 [self.chatMessages addObject:chatMessage];
                                 [self.chatTableView reloadData];
                             }
    }];
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
    return self.chatMessages.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ChatTableViewCell   *cell;
    WLChatMessage *chatMessage = [self.chatMessages objectAtIndex:indexPath.row];
    
    if (chatMessage.messageType == ChatMessageTypeInfo) {
        cell = [tableView dequeueReusableCellWithIdentifier:kChatInfoCellIndentifier];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:kChatMessageCellIndentifier];
    }
    cell.messageLabel.text = chatMessage.content;
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
