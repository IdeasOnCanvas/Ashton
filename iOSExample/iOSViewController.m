#import "iOSViewController.h"
#import "iOSAppDelegate.h"
#import "AshtonCoreText.h"

@interface iOSViewController ()

@end

@implementation iOSViewController

- (void)viewWillAppear:(BOOL)animated
{
    NSAttributedString *intermediate = ((iOSAppDelegate *)[[UIApplication sharedApplication] delegate]).intermediateAS;
    self.coreTextView.attributedString = [[AshtonCoreText sharedInstance] targetRepresentationWithIntermediateRepresentation:intermediate];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSAttributedString *intermediate = [[AshtonCoreText sharedInstance] intermediateRepresentationWithTargetRepresentation:self.coreTextView.attributedString];
    ((iOSAppDelegate *)[[UIApplication sharedApplication] delegate]).intermediateAS = intermediate;
    [super viewWillDisappear:animated];
}

@end
