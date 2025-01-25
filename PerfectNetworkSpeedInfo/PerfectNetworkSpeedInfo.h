@interface UIView (Private)
    -(id)_viewControllerForAncestor;
@end

@interface _UIStatusBarForegroundView : UIView
    @property (nonatomic, retain) UILabel *networkSpeedLabel;
    @property (nonatomic, retain) NSTimer *networkSpeedLabelTimer;
@end

@interface SBControlCenterController: NSObject
+ (id)sharedInstance;
- (BOOL)isVisible;
@end