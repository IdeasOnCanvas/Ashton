#import "OSXAppDelegate.h"
#import "NSAttributedString+MSAttributedStringSerialization.h"

@implementation OSXAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSAttributedString *source = [self readAttributedStringFromRTFFile:@"TextEdit Test Document"];
    NSAttributedString *intermediate = [source intermediateAttributedStringWithAppKitAttributes];

    self.sourceTextView.textStorage.attributedString = source;
    self.appKitTextView.textStorage.attributedString = [NSAttributedString attributedStringWithAppKitAttributes:intermediate];
    self.coreTextView.attributedString = [NSAttributedString attributedStringWithCoreTextAttributes:intermediate];;
}

- (NSAttributedString *)readAttributedStringFromRTFFile:(NSString *)name {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"rtf"];
    NSTextView *text = [[NSTextView alloc] init];
    [text readRTFDFromFile:path];
    return [text attributedString];
}

@end
