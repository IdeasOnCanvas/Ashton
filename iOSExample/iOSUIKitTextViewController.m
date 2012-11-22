#import "iOSUIKitTextViewController.h"
#import "MNAttributedStringUIKit.h"
#import "iOSAppDelegate.h"

@interface iOSUIKitTextViewController ()

@end

@implementation iOSUIKitTextViewController

- (void)viewWillAppear:(BOOL)animated {
    NSAttributedString *intermediate = ((iOSAppDelegate *)[[UIApplication sharedApplication] delegate]).intermediateAS;
    self.textView.attributedText = [[MNAttributedStringUIKit shared] targetRepresentationWithIntermediateRepresentation:intermediate];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    NSAttributedString *intermediate = [[MNAttributedStringUIKit shared] intermediateRepresentationWithTargetRepresentation:self.textView.attributedText];
    ((iOSAppDelegate *)[[UIApplication sharedApplication] delegate]).intermediateAS = intermediate;
    [super viewWillDisappear:animated];
}

@end
