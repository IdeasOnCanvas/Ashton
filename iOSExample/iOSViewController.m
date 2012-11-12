#import "iOSViewController.h"
#import "iOSAppDelegate.h"

@interface iOSViewController ()

@end

@implementation iOSViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.coreTextView.attributedString = ((iOSAppDelegate *)[[UIApplication sharedApplication] delegate]).coreTextAS;
}

@end
