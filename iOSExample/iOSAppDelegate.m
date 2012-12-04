#import "iOSAppDelegate.h"
#import "AshtonHTMLReader.h"

@implementation iOSAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    self.intermediateAS = [self readAttributedStringFromHTMLFile:@"Test1"];
}

- (NSAttributedString *)readAttributedStringFromHTMLFile:(NSString *)name {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"html"];
    NSString *html = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    return [[AshtonHTMLReader sharedInstance] attributedStringFromHTMLString:html];
}

@end
