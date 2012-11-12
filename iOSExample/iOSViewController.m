#import "iOSViewController.h"
#import "iOSAppDelegate.h"
#import "NSAttributedString+MNAttributedStringConversions.h"

@interface iOSViewController ()

@end

@implementation iOSViewController

- (void)viewWillAppear:(BOOL)animated {
    NSAttributedString *intermediate = ((iOSAppDelegate *)[[UIApplication sharedApplication] delegate]).intermediateAS;
    self.coreTextView.attributedString = [NSAttributedString attributedStringWithCoreTextAttributes:intermediate];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    NSAttributedString *intermediate = [self.coreTextView.attributedString intermediateAttributedStringWithCoreTextAttributes];
    ((iOSAppDelegate *)[[UIApplication sharedApplication] delegate]).intermediateAS = intermediate;
    [super viewWillDisappear:animated];
}

@end
