#import "PerfectNetworkSpeedInfo.h"
#import <ifaddrs.h>
#import <net/if.h>

static BOOL networkSpeedEnabled = YES;

%group NetworkSpeed

	static const long KILOBITS = 1000;
	static const long MEGABITS = 1000000;
	static const long KILOBYTES = 1 << 10;
	static const long MEGABYTES = 1 << 20;

	static long oldUpSpeed = 0, oldDownSpeed = 0;
	typedef struct
	{
		uint32_t inputBytes;
		uint32_t outputBytes;
	} UpDownBytes;

	static BOOL showUploadSpeed = YES;
	static NSString *uploadPrefix = @"↑";
	static BOOL showDownloadSpeed = YES;
	static NSString *downloadPrefix = @"↓";
	static NSString *separator = @" ";

	static NSInteger dataUnit = 0;
	static NSInteger minimumUnit = 0;

	static double portraitX = 135;
	static double portraitY = 1;

	static double width = 120;
	static double height = 13;
	static double fontSize = 12.5;
	static int fontWeight = 6;
	static int alignment = 1;
	static double updateInterval = 1;

	// Got some help from similar network speed tweaks by julioverne & n3d1117

	NSString* formatSpeed(long bytes) {
		if(dataUnit == 0) // BYTES
		{
			if(bytes < KILOBYTES)
			{
				if(minimumUnit == 0)
					return [NSString stringWithFormat: @"%ldB/s", bytes];
				else
					return @"0KB/s";
			}
			else if(bytes < MEGABYTES) return [NSString stringWithFormat: @"%.0fKB/s", (double)bytes / KILOBYTES];
			else return [NSString stringWithFormat: @"%.2fMB/s", (double)bytes / MEGABYTES];
		}
		else // BITS
		{
			if(bytes < KILOBITS)
			{
				if(minimumUnit == 0)
					return [NSString stringWithFormat: @"%ldb/s", bytes];
				else
					return @"0Kb/s";
			}
			else if(bytes < MEGABITS) return [NSString stringWithFormat: @"%.0fKb/s", (double)bytes / KILOBITS];
			else return [NSString stringWithFormat: @"%.2fMb/s", (double)bytes / MEGABITS];
		}
	}

	UpDownBytes getUpDownBytes() {
		struct ifaddrs *ifa_list = 0, *ifa;
		UpDownBytes upDownBytes;
		upDownBytes.inputBytes = 0;
		upDownBytes.outputBytes = 0;
		
		if((getifaddrs(&ifa_list) < 0) || !ifa_list || ifa_list == 0)
			return upDownBytes;

		for(ifa = ifa_list; ifa; ifa = ifa->ifa_next)
		{
			if(ifa->ifa_addr == NULL
			|| AF_LINK != ifa->ifa_addr->sa_family
			|| (!(ifa->ifa_flags & IFF_UP) && !(ifa->ifa_flags & IFF_RUNNING))
			|| ifa->ifa_data == NULL || ifa->ifa_data == 0
			|| strstr(ifa->ifa_name, "lo0")
			|| strstr(ifa->ifa_name, "utun"))
				continue;
			
			struct if_data *if_data = (struct if_data *)ifa->ifa_data;

			upDownBytes.inputBytes += if_data->ifi_ibytes;
			upDownBytes.outputBytes += if_data->ifi_obytes;
		}
		if(ifa_list)
			freeifaddrs(ifa_list);

		return upDownBytes;
	}

	static NSMutableString* formattedString() {
		NSMutableString* mutableString = [[NSMutableString alloc] init];
		
		UpDownBytes upDownBytes = getUpDownBytes();
		long upDiff = (upDownBytes.outputBytes - oldUpSpeed) / updateInterval;
		long downDiff = (upDownBytes.inputBytes - oldDownSpeed) / updateInterval;
		oldUpSpeed = upDownBytes.outputBytes;
		oldDownSpeed = upDownBytes.inputBytes;

		if(dataUnit == 1) // BITS
		{
			upDiff *= 8;
			downDiff *= 8;
		}

		if(upDiff > 50 * MEGABYTES && downDiff > 50 * MEGABYTES)
		{
			upDiff = 0;
			downDiff = 0;
		}

		if(showUploadSpeed) [mutableString appendString: [NSString stringWithFormat: @"%@%@", uploadPrefix, formatSpeed(upDiff)]];
		if(showDownloadSpeed)
		{
			if([mutableString length] > 0)
				[mutableString appendString: separator];

			[mutableString appendString: [NSString stringWithFormat: @"%@%@", downloadPrefix, formatSpeed(downDiff)]];
		}
		
		return [mutableString copy];
	}

	static UIFontWeight getFontWeight(int fontWeight) {
		if (fontWeight == 3)
			return UIFontWeightRegular;
		else if (fontWeight == 5)
			return UIFontWeightSemibold;										
		else if (fontWeight == 7)
			return UIFontWeightHeavy;		
		else
			return UIFontWeightBold;
	}	

	%hook _UIStatusBar

		-(void)setAlpha:(CGFloat)arg1 forPartWithIdentifier:(id)arg2 {
			%orig;
			NSLog(@"KPD %f %@",arg1,arg2);
		}
	
	
	%end

	%hook _UIStatusBarForegroundView

		%property (nonatomic, retain) UILabel *networkSpeedLabel;
		%property (nonatomic, retain) NSTimer *networkSpeedLabelTimer;

		- (void)willMoveToSuperview:(UIView *)newSuperview
		{
			%orig;

			if (newSuperview) {
				if (!self.networkSpeedLabel && !([newSuperview.superview.superview isKindOfClass:NSClassFromString(@"CCUIStatusBar")])) {
					self.networkSpeedLabel = [[UILabel new] initWithFrame:CGRectZero];
					[self addSubview: self.networkSpeedLabel];

					self.networkSpeedLabelTimer = [NSTimer scheduledTimerWithTimeInterval: updateInterval target: self selector: @selector(updateNetworkSpeedLabel) userInfo: nil repeats: YES];
					return;
				}
			}

			if (self.networkSpeedLabelTimer) {
				[self.networkSpeedLabelTimer invalidate];
				self.networkSpeedLabelTimer = nil;
			}

			if (self.networkSpeedLabel) {
				[self.networkSpeedLabel removeFromSuperview];
				self.networkSpeedLabel = nil;
			}						
		}

		%new
		- (void)updateNetworkSpeedLabel {
			if(self.networkSpeedLabel)
			{
				if ([[%c(SBControlCenterController) sharedInstance] isVisible])
					self.networkSpeedLabel.hidden = YES;
				else
					self.networkSpeedLabel.hidden = NO;

				self.networkSpeedLabel.frame = CGRectMake(portraitX,portraitY,width,height);
				NSString *speed = formattedString();
				[self.networkSpeedLabel setText: speed];							
				[self.networkSpeedLabel setFont: [UIFont systemFontOfSize: fontSize weight: getFontWeight(fontWeight)]];
				[self.networkSpeedLabel setTextAlignment: alignment];				
			}
		}	
	%end

	static void settingsChanged() {
		static CFStringRef prefsKey = CFSTR("com.johnzaro.networkspeed13prefs");
		CFPreferencesAppSynchronize(prefsKey);   

		if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"enabled", prefsKey))) {
			networkSpeedEnabled = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"enabled", prefsKey)) boolValue];
		}

		if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"showUploadSpeed", prefsKey))) {
			showUploadSpeed = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"showUploadSpeed", prefsKey)) boolValue];
		}

		if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"uploadPrefix", prefsKey))) {
			uploadPrefix = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"uploadPrefix", prefsKey)) stringValue];
		}	

		if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"showDownloadSpeed", prefsKey))) {
			showDownloadSpeed = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"showDownloadSpeed", prefsKey)) boolValue];
		}		

		if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"downloadPrefix", prefsKey))) {
			downloadPrefix = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"downloadPrefix", prefsKey)) stringValue];
		}

		if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"separator", prefsKey))) {
			separator = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"separator", prefsKey)) stringValue];
		}	

		if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"dataUnit", prefsKey))) {
			dataUnit = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"dataUnit", prefsKey)) intValue];
		}
		
		if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"minimumUnit", prefsKey))) {
			minimumUnit = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"minimumUnit", prefsKey)) intValue];
		}

		if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"portraitX", prefsKey))) {
			portraitX = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"portraitX", prefsKey)) doubleValue];
		}	

		if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"portraitY", prefsKey))) {
			portraitY = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"portraitY", prefsKey)) doubleValue];
		}

		if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"width", prefsKey))) {
			width = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"width", prefsKey)) doubleValue];
		}	

		if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"height", prefsKey))) {
			height = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"height", prefsKey)) doubleValue];
		}	

		if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"fontSize", prefsKey))) {
			fontSize = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"fontSize", prefsKey)) doubleValue];
		}

		if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"fontWeight", prefsKey))) {
			fontWeight = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"fontWeight", prefsKey)) intValue];
		}	

		if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"alignment", prefsKey))) {
			alignment = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"alignment", prefsKey)) intValue];
		}

		if (CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"updateInterval", prefsKey))) {
			updateInterval = [(id)CFBridgingRelease(CFPreferencesCopyAppValue((CFStringRef)@"updateInterval", prefsKey)) intValue];
		}					
	}
%end

%ctor {
	settingsChanged();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)settingsChanged, CFSTR("com.johnzaro.networkspeed13prefs/ReloadPrefs"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	if (networkSpeedEnabled)
		%init(NetworkSpeed);
}