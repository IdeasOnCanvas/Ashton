#import "OSXAppDelegate.h"
#import "NSAttributedString+Ashton.h"

@implementation OSXAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSAttributedString *source = [self readAttributedStringFromRTFFile:@"TextEdit Test Document"];
    NSAttributedString *intermediate = [source intermediateAttributedStringWithAppKitAttributes];

    self.sourceTextView.textStorage.attributedString = source;
    self.appKitTextView.textStorage.attributedString = [NSAttributedString attributedStringWithAppKitAttributes:intermediate];
    self.coreTextView.attributedString = [NSAttributedString attributedStringWithCoreTextAttributes:intermediate];

    NSAttributedString *coreTextAndBackToIntermediate = [[NSAttributedString attributedStringWithCoreTextAttributes:intermediate] intermediateAttributedStringWithCoreTextAttributes];
    self.appKitAgainTextView.textStorage.attributedString = [NSAttributedString attributedStringWithAppKitAttributes:coreTextAndBackToIntermediate];


    NSString *output = [intermediate HTMLRepresentation];
    [output writeToFile:@"/Users/msch/Desktop/test.html" atomically:YES encoding:NSUnicodeStringEncoding error:nil];
}

- (NSAttributedString *)readAttributedStringFromRTFFile:(NSString *)name {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"rtf"];
    NSTextView *text = [[NSTextView alloc] init];
    [text readRTFDFromFile:path];
    return [text attributedString];
}

@end
