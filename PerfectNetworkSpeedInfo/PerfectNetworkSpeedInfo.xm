#import "PerfectNetworkSpeedInfo.h"
#import <ifaddrs.h>
#import <net/if.h>

static BOOL networkSpeedEnabled = YES;

%group NetworkSpeed

	#define KILOBITS 1000
	#define MEGABITS 1000000
	#define GIGABITS 1000000000
	#define KILOBYTES (1 << 10)
	#define MEGABYTES (1 << 20)
	#define GIGABYTES (1 << 30)

	static uint64_t prevOutputBytes = 0, prevInputBytes = 0;
	typedef struct
	{
		uint64_t inputBytes;
		uint64_t outputBytes;
	} UpDownBytes;

	static NSString *networkSpeed;

	static BOOL showUploadSpeed = YES;
	static NSString *uploadPrefix = @"↑";
	static BOOL showDownloadSpeed = YES;
	static NSString *downloadPrefix = @"↓";
	static NSString *separator = @" ";

	static NSInteger dataUnit = 0;

	static double portraitX = 135;
	static double portraitY = 1;

	static double width = 120;
	static double height = 13;
	static double fontSize = 12.5;
	static int fontWeight = 6;
	static int alignment = 1;

	// Got some help from similar network speed tweaks by julioverne & n3d1117

	NSString* formatSpeed(long long bytes) {
		if(dataUnit == 0) // BYTES
		{
			if (bytes < KILOBYTES)
				return @"0 B/s";
			else if (bytes < MEGABYTES) 
				return [NSString stringWithFormat: @"%.0f KB/s", (double)bytes / KILOBYTES];
			else if (bytes < GIGABYTES) 
				return [NSString stringWithFormat: @"%.2f MB/s", (double)bytes / MEGABYTES];
			else 
				return [NSString stringWithFormat: @"%.2f GB/s", (double)bytes / GIGABYTES];
		}
		else // BITS
		{
			if (bytes < KILOBITS)
				return @"0 b/s";
			else if (bytes < MEGABITS) 
				return [NSString stringWithFormat: @"%.0f Kb/s", (double)bytes / KILOBITS];
			else if (bytes < GIGABITS) 
				return [NSString stringWithFormat: @"%.2f Mb/s", (double)bytes / MEGABITS];
			else 
				return [NSString stringWithFormat: @"%.2f Gb/s", (double)bytes / GIGABITS];
		}
	}

	static UpDownBytes getUpDownBytes()
	{
		struct ifaddrs *ifa_list = 0, *ifa;
		UpDownBytes upDownBytes;
		upDownBytes.inputBytes = 0;
		upDownBytes.outputBytes = 0;
		
		if (getifaddrs(&ifa_list) == -1) return upDownBytes;

		for (ifa = ifa_list; ifa; ifa = ifa->ifa_next)
		{
			/* Skip invalid interfaces */
			if (ifa->ifa_name == NULL || ifa->ifa_addr == NULL || ifa->ifa_data == NULL)
				continue;
			
			/* Skip interfaces that are not link level interfaces */
			if (AF_LINK != ifa->ifa_addr->sa_family)
				continue;

			/* Skip interfaces that are not up or running */
			if (!(ifa->ifa_flags & IFF_UP) && !(ifa->ifa_flags & IFF_RUNNING))
				continue;
			
			/* Skip interfaces that are not ethernet or cellular */
			if (strncmp(ifa->ifa_name, "en", 2) && strncmp(ifa->ifa_name, "pdp_ip", 6))
				continue;
			
			struct if_data *if_data = (struct if_data *)ifa->ifa_data;
			
			upDownBytes.inputBytes += if_data->ifi_ibytes;
			upDownBytes.outputBytes += if_data->ifi_obytes;
		}
		
		freeifaddrs(ifa_list);
		return upDownBytes;
	}

	static NSMutableString* formattedString() {
		NSMutableString* mutableString = [[NSMutableString alloc] init];
		
		UpDownBytes upDownBytes = getUpDownBytes();
		uint64_t upDiff;
		uint64_t downDiff;

		if (upDownBytes.outputBytes > prevOutputBytes)
			upDiff = upDownBytes.outputBytes - prevOutputBytes;
		else
			upDiff = 0;
		
		if (upDownBytes.inputBytes > prevInputBytes)
			downDiff = upDownBytes.inputBytes - prevInputBytes;
		else
			downDiff = 0;

		prevOutputBytes = upDownBytes.outputBytes;
		prevInputBytes = upDownBytes.inputBytes;

		if(dataUnit == 1) // BITS
		{
			upDiff *= 8;
			downDiff *= 8;
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

	%hook SBBacklightController

		-(void)_notifyObserversWillAnimateToFactor:(float)arg1 source:(long long)arg2 {
			if (arg1 == 0)
				[[NSNotificationCenter defaultCenter] postNotificationName:@"stopNetworkSpeedTimer" object:nil];
			else
				[[NSNotificationCenter defaultCenter] postNotificationName:@"startNetworkSpeedTimer" object:nil];
			%orig;
		}

	%end	

	%hook _UIStatusBar

		%property (nonatomic, retain) UILabel *networkSpeedLabel;

		-(UIView *)foregroundView {
			UIView *foregroundView = %orig;

			if (!self.networkSpeedLabel) {
				self.networkSpeedLabel = [[UILabel new] initWithFrame:CGRectZero];
				[self.networkSpeedLabel setAdjustsFontSizeToFitWidth: YES];
				[foregroundView insertSubview:self.networkSpeedLabel atIndex:1];

				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNetworkSpeedText) name:@"updateNetworkSpeedText" object:nil];
			}

			return foregroundView;					
		}

		-(void)dealloc {
			[[NSNotificationCenter defaultCenter] removeObserver:self];
			%orig;
		}				

		%new
		- (void)updateNetworkSpeedText {
			if(self.networkSpeedLabel)
			{
				self.networkSpeedLabel.frame = CGRectMake(portraitX,portraitY,width,height);
				[self.networkSpeedLabel setText: networkSpeed];							
				[self.networkSpeedLabel setFont: [UIFont systemFontOfSize: fontSize weight: getFontWeight(fontWeight)]];
				[self.networkSpeedLabel setTextAlignment: alignment];
				if ([self.superview.superview isKindOfClass:NSClassFromString(@"CCUIStatusBar")])
					self.networkSpeedLabel.hidden = YES;
				else
					self.networkSpeedLabel.hidden = NO;
			}
		}	
	%end

	static NSTimer *networkSpeedTimer = nil;

	%hook SpringBoard

		-(void)applicationDidFinishLaunching:(id)application {
			%orig;			
			[self startNetworkSpeedTimer];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startNetworkSpeedTimer) name:@"startNetworkSpeedTimer" object:nil];			
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopNetworkSpeedTimer) name:@"stopNetworkSpeedTimer" object:nil];			
		}

		%new
			-(void)startNetworkSpeedTimer {
				if (networkSpeedTimer) {
					[self stopNetworkSpeedTimer];
				}

				networkSpeedTimer = [NSTimer scheduledTimerWithTimeInterval: 1.0 target: self selector: @selector(updateNetworkSpeed) userInfo: nil repeats: YES];				
			}

		%new
			-(void)stopNetworkSpeedTimer {
				if (networkSpeedTimer) {
					[networkSpeedTimer invalidate];
					networkSpeedTimer = nil;
				}				
			}			

		%new
			-(void)updateNetworkSpeed {
				dispatch_async(dispatch_get_main_queue(), ^{
					networkSpeed = formattedString();
					[[NSNotificationCenter defaultCenter] postNotificationName:@"updateNetworkSpeedText" object:nil];
				});				
			}			
	%end

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
}

%ctor {
	settingsChanged();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)settingsChanged, CFSTR("com.johnzaro.networkspeed13prefs/ReloadPrefs"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	if (networkSpeedEnabled)
		%init(NetworkSpeed);
}