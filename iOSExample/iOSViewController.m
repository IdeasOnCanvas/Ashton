#import "iOSViewController.h"
#import "NSAttributedString+MNAttributedStringConversions.h"

@interface iOSViewController ()

@end

@implementation iOSViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSAttributedString *intermediate = [self readAttributedStringFromHTMLFile:@"Test1"];
    self.coreTextView.attributedString = [NSAttributedString attributedStringWithCoreTextAttributes:intermediate];
}

- (NSAttributedString *)readAttributedStringFromHTMLFile:(NSString *)name {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"html"];
    NSString *html = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    return [NSAttributedString intermediateAttributedStringFromHTML:html];
}

@end
