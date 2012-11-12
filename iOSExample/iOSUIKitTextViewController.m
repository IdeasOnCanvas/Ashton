#import "iOSUIKitTextViewController.h"
#import "iOSAppDelegate.h"

@interface iOSUIKitTextViewController ()

@end

@implementation iOSUIKitTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textView.attributedText = ((iOSAppDelegate *)[[UIApplication sharedApplication] delegate]).UIKitAS;
}

@end
