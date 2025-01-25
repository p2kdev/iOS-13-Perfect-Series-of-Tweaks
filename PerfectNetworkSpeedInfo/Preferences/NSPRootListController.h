#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSHeaderFooterView.h>

@interface NSPRootListController: PSListController
{
    UITableView *_table;
}
@property(nonatomic, retain) UIBarButtonItem *respringButton;
@property(nonatomic, retain) UILabel *titleLabel;
- (void)respring;
@end

@interface MFMailComposeViewController: UINavigationController
+ (BOOL)canSendMail;
- (void)setMailComposeDelegate: (id)arg1;
- (id)mailComposeDelegate;
- (void)setToRecipients: (id)arg1;
@end