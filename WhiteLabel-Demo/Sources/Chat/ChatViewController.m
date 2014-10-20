//
//  ChatViewController.m
//  WhiteLabel-Demo
//
//  Created by Ahuja on 20/10/14.
//  Copyright (c) 2014 Fueled. All rights reserved.
//

#import "ChatViewController.h"
#import "WhiteLabel.h"
#import "ChatMessage.h"
#import "ChatTableViewCell.h"

@interface ChatViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSMutableArray    *chatMessages;
@property (nonatomic, weak) IBOutlet UITableView    *chatTableView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint   *chatMessageViewBottomConstraint;

@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setUpNotificationListeners];
    [self initializeChat];
    [self setKeyboardNotifications];
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

- (void)initializeChat {
    
    self.chatTableView.estimatedRowHeight = 44.0f;
    self.chatTableView.rowHeight = UITableViewAutomaticDimension;
    
    NSString    *content = [NSString stringWithFormat:@"%@ users in chat", self.userCount];
    ChatMessage *chatMessage = [[ChatMessage alloc] initWithMessageType:ChatMessageTypeInfo
                                                                content:content];
    self.chatMessages = [NSMutableArray arrayWithObject:chatMessage];
    [self.chatTableView reloadData];
}

- (void)newMessageReceived: (NSNotification*)notification {
    
    NSString    *userName = notification.userInfo[@"username"];
    NSString    *message = notification.userInfo[@"message"];
    NSString    *content = [NSString stringWithFormat:@"%@ : %@", userName, message];
    ChatMessage *chatMessage = [[ChatMessage alloc] initWithMessageType:ChatMessageTypeMessage
                                                                content:content];
    [self.chatMessages addObject:chatMessage];
    [self.chatTableView reloadData];
    
}

- (void)userJoinedChat: (NSNotification*)notification {
    
}

- (void)userLeftChat: (NSNotification*)notification {
    
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


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark UITableView Datasource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.chatMessages.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ChatTableViewCell   *cell;
    ChatMessage *chatMessage = [self.chatMessages objectAtIndex:indexPath.row];
    
    if (chatMessage.messageType == ChatMessageTypeInfo) {
        cell = [tableView dequeueReusableCellWithIdentifier:kChatInfoCellIndentifier];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:kChatMessageCellIndentifier];
    }
    cell.messageLabel.text = chatMessage.content;
    [cell.messageLabel sizeToFit];
    return cell;
}

@end
