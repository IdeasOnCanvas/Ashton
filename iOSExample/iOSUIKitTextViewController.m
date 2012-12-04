#import "iOSUIKitTextViewController.h"
#import "AshtonUIKit.h"
#import "iOSAppDelegate.h"

@interface iOSUIKitTextViewController ()

@end

@implementation iOSUIKitTextViewController

- (void)viewWillAppear:(BOOL)animated {
    NSAttributedString *intermediate = ((iOSAppDelegate *)[[UIApplication sharedApplication] delegate]).intermediateAS;
    self.textView.attributedText = [[AshtonUIKit sharedInstance] targetRepresentationWithIntermediateRepresentation:intermediate];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    NSAttributedString *intermediate = [[AshtonUIKit sharedInstance] intermediateRepresentationWithTargetRepresentation:self.textView.attributedText];
    ((iOSAppDelegate *)[[UIApplication sharedApplication] delegate]).intermediateAS = intermediate;
    [super viewWillDisappear:animated];
}

@end
