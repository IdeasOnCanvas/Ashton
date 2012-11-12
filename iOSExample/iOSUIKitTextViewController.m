#import "iOSUIKitTextViewController.h"
#import "NSAttributedString+MNAttributedStringConversions.h"
#import "iOSAppDelegate.h"

@interface iOSUIKitTextViewController ()

@end

@implementation iOSUIKitTextViewController

- (void)viewWillAppear:(BOOL)animated {
    NSAttributedString *intermediate = ((iOSAppDelegate *)[[UIApplication sharedApplication] delegate]).intermediateAS;
    self.textView.attributedText = [NSAttributedString attributedStringWithUIKitAttributes:intermediate];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    NSAttributedString *intermediate = [self.textView.attributedText intermediateAttributedStringWithUIKitAttributes];
    ((iOSAppDelegate *)[[UIApplication sharedApplication] delegate]).intermediateAS = intermediate;
    [super viewWillDisappear:animated];
}

@end
