@interface UIView (Private)
    -(id)_viewControllerForAncestor;
@end

@interface UISystemGestureView : UIView
    @property (nonatomic, retain) UILabel *networkSpeedLabel;
    @property (nonatomic, retain) NSTimer *networkSpeedLabelTimer;
    -(void)startNetworkSpeedLabelSecondsTimer;
    -(void)stopNetworkSpeedLabelSecondsTimer;
@end

@interface _UIStatusBar : UIView
    @property (nonatomic, retain) UILabel *networkSpeedLabel;
    @property (nonatomic, retain) NSTimer *networkSpeedLabelTimer;
    -(void)startNetworkSpeedLabelSecondsTimer;
    -(void)stopNetworkSpeedLabelSecondsTimer;
    -(NSArray *)enabledPartIdentifiers;
@end

@interface _UIStatusBarForegroundView : UIView
    @property (nonatomic, retain) UILabel *networkSpeedLabel;
    @property (nonatomic, retain) NSTimer *networkSpeedLabelTimer;
    -(void)startNetworkSpeedLabelSecondsTimer;
    -(void)stopNetworkSpeedLabelSecondsTimer;
@end

@interface SBControlCenterController: NSObject
    + (id)sharedInstance;
    - (BOOL)isVisible;
    -(BOOL)isDismissedOrDismissing;
@end

@interface UIStatusBar_Base
    @property (nonatomic, strong, readwrite) UIColor *foregroundColor;
    @property (nonatomic, assign, readwrite) CGFloat alpha;
@end

@interface SpringBoard
    -(void)startNetworkSpeedTimer;
    -(void)stopNetworkSpeedTimer;
@end

@interface PCSimpleTimer : NSObject
    @property BOOL disableSystemWaking;
    - (BOOL)disableSystemWaking;
    - (id)initWithFireDate:(id)arg1 serviceIdentifier:(id)arg2 target:(id)arg3 selector:(SEL)arg4 userInfo:(id)arg5;
    - (id)initWithTimeInterval:(double)arg1 serviceIdentifier:(id)arg2 target:(id)arg3 selector:(SEL)arg4 userInfo:(id)arg5;
    - (void)invalidate;
    - (BOOL)isValid;
    - (void)scheduleInRunLoop:(id)arg1;
    - (void)setDisableSystemWaking:(BOOL)arg1;
    - (id)userInfo;
@end