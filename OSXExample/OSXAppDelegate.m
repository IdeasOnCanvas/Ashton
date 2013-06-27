#import "OSXAppDelegate.h"
#import "NSAttributedString+Ashton.h"
#import "AshtonHTMLReader.h"
#import "AshtonAppKit.h"
#import "AshtonCoreText.h"

@implementation OSXAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSAttributedString *source = [self readAttributedStringFromRTFFile:@"Test1"];
    NSAttributedString *intermediate = [[AshtonHTMLReader HTMLReader] attributedStringFromHTMLString:[source mn_HTMLRepresentation]];

    self.sourceTextView.textStorage.attributedString = source;
    self.appKitTextView.textStorage.attributedString = [[AshtonAppKit sharedInstance] targetRepresentationWithIntermediateRepresentation:intermediate];
    self.coreTextView.attributedString = [[AshtonCoreText sharedInstance] targetRepresentationWithIntermediateRepresentation:intermediate];

    NSAttributedString *coreTextAndBackToIntermediate = [[AshtonCoreText sharedInstance] intermediateRepresentationWithTargetRepresentation:self.coreTextView.attributedString];
    self.appKitAgainTextView.textStorage.attributedString = [[AshtonAppKit sharedInstance] targetRepresentationWithIntermediateRepresentation:coreTextAndBackToIntermediate];
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
