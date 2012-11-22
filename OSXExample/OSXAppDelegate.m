#import "OSXAppDelegate.h"
#import "NSAttributedString+MNAttributedStringConversions.h"
#import "MNAttributedStringHTMLReader.h"
#import "MNAttributedStringAppKit.h"
#import "MNAttributedStringCoreText.h"

@implementation OSXAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSAttributedString *source = [self readAttributedStringFromRTFFile:@"Test1"];
    NSAttributedString *intermediate = [[MNAttributedStringHTMLReader sharedInstance] attributedStringFromHTMLString:[source mn_HTMLRepresentation]];

    self.sourceTextView.textStorage.attributedString = source;
    self.appKitTextView.textStorage.attributedString = [[MNAttributedStringAppKit sharedInstance] targetRepresentationWithIntermediateRepresentation:intermediate];
    self.coreTextView.attributedString = [[MNAttributedStringCoreText sharedInstance] targetRepresentationWithIntermediateRepresentation:intermediate];

    NSAttributedString *coreTextAndBackToIntermediate = [[MNAttributedStringCoreText sharedInstance] intermediateRepresentationWithTargetRepresentation:self.coreTextView.attributedString];
    self.appKitAgainTextView.textStorage.attributedString = [[MNAttributedStringAppKit sharedInstance] targetRepresentationWithIntermediateRepresentation:coreTextAndBackToIntermediate];

    NSString *desktopPath = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    [[intermediate mn_HTMLRepresentation] writeToFile:[desktopPath stringByAppendingPathComponent:@"test.html"] atomically:YES encoding:NSUnicodeStringEncoding error:nil];
}

- (NSAttributedString *)readAttributedStringFromRTFFile:(NSString *)name
{
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"rtf"];
    return [self readAttributedStringFromRTFPath:path];
}

- (NSAttributedString *)readAttributedStringFromRTFPath:(NSString *)path
{
    NSTextView *text = [[NSTextView alloc] init];
    [text readRTFDFromFile:path];
    return [text attributedString];
}

- (IBAction)convertAppKitRTFIntoHTML:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    if ([openPanel runModal] != NSFileHandlingPanelOKButton) return;
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    if ([savePanel runModal] != NSFileHandlingPanelOKButton) return;

    NSAttributedString *appKitString = [self readAttributedStringFromRTFPath:[openPanel.URL path]];
    NSString *html = [appKitString mn_HTMLRepresentation];
    [html writeToURL:savePanel.URL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

@end
