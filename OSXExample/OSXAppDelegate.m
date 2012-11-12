#import "OSXAppDelegate.h"
#import "NSAttributedString+MNAttributedStringConversions.h"

@implementation OSXAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSAttributedString *source = [self readAttributedStringFromRTFFile:@"Test1"];
    NSAttributedString *intermediate = [NSAttributedString intermediateAttributedStringFromHTML:[[source intermediateAttributedStringWithAppKitAttributes] HTMLRepresentation]];

    self.sourceTextView.textStorage.attributedString = source;
    self.appKitTextView.textStorage.attributedString = [NSAttributedString attributedStringWithAppKitAttributes:intermediate];
    self.coreTextView.attributedString = [NSAttributedString attributedStringWithCoreTextAttributes:intermediate];

    NSAttributedString *coreTextAndBackToIntermediate = [[NSAttributedString attributedStringWithCoreTextAttributes:intermediate] intermediateAttributedStringWithCoreTextAttributes];
    self.appKitAgainTextView.textStorage.attributedString = [NSAttributedString attributedStringWithAppKitAttributes:coreTextAndBackToIntermediate];

    NSString *desktopPath = [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    [[intermediate HTMLRepresentation] writeToFile:[desktopPath stringByAppendingPathComponent:@"test.html"] atomically:YES encoding:NSUnicodeStringEncoding error:nil];
}

- (NSAttributedString *)readAttributedStringFromRTFFile:(NSString *)name {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"rtf"];
    return [self readAttributedStringFromRTFPath:path];
}

- (NSAttributedString *)readAttributedStringFromRTFPath:(NSString *)path {
    NSTextView *text = [[NSTextView alloc] init];
    [text readRTFDFromFile:path];
    return [text attributedString];
}

- (IBAction)convertAppKitRTFIntoHTML:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    if ([openPanel runModal] != NSFileHandlingPanelOKButton) return;
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    if ([savePanel runModal] != NSFileHandlingPanelOKButton) return;

    NSAttributedString *appKitString = [self readAttributedStringFromRTFPath:[openPanel.URL path]];
    NSString *html = [[appKitString intermediateAttributedStringWithAppKitAttributes] HTMLRepresentation];
    [html writeToURL:savePanel.URL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

@end
