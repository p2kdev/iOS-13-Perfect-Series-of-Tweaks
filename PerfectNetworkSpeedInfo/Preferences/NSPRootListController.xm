#import "NSPRootListController.h"
#import "spawn.h"

@implementation NSPRootListController

- (instancetype)init
{
    self = [super init];
    return self;
}

- (NSArray*)specifiers
{
	if (!_specifiers) _specifiers = [self loadSpecifiersFromPlistName: @"Root" target: self];
	return _specifiers;
}

- (void)reset: (PSSpecifier*)specifier
{
    UIAlertController *reset = [UIAlertController
        alertControllerWithTitle: @"PerfectNetworkSpeedInfo"
		message: @"Do you really want to Reset All Settings?"
		preferredStyle: UIAlertControllerStyleAlert];
	UIAlertAction *confirmAction = [UIAlertAction actionWithTitle: @"Confirm" style: UIAlertActionStyleDestructive handler:
        ^(UIAlertAction * action)
        {
            NSFileManager *manager = [NSFileManager defaultManager];
            [manager removeItemAtPath: @"/var/jb/var/mobile/Library/Preferences/com.johnzaro.networkspeed13prefs.plist" error: nil];

            [self respring];
        }];

	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle: @"Cancel" style: UIAlertActionStyleCancel handler: nil];
	[reset addAction: confirmAction];
	[reset addAction: cancelAction];
	[self presentViewController: reset animated: YES completion: nil];
}

- (void)respring
{
	pid_t pid;
	const char *args[] = {"sbreload", NULL, NULL, NULL};
	posix_spawn(&pid, "/var/jb/usr/bin/sbreload", NULL, NULL, (char *const *)args, NULL);
}

- (void)email
{
	if([%c(MFMailComposeViewController) canSendMail])
	{
		MFMailComposeViewController *mailCont = [[%c(MFMailComposeViewController) alloc] init];
		mailCont.mailComposeDelegate = self;

		[mailCont setToRecipients: [NSArray arrayWithObject: @"johnzrgnns@gmail.com"]];
		[self presentViewController: mailCont animated: YES completion: nil];
	}
}

- (void)reddit
{
	if([[UIApplication sharedApplication] canOpenURL: [NSURL URLWithString: @"reddit://"]])
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"reddit://www.reddit.com/user/johnzaro"]];
	else
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.reddit.com/user/johnzaro"]];
}

- (void)donate
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://paypal.me/JohnZarogiannis"]];
}

-(void)mailComposeController:(id)arg1 didFinishWithResult:(long long)arg2 error:(id)arg3
{
    [self dismissViewControllerAnimated: YES completion: nil];
}

@end
