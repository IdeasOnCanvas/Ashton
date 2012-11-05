#import "OSXAppDelegate.h"
#import "NSAttributedString+MSAttributedStringSerialization.h"

@implementation OSXAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSAttributedString *source = [[self readAttributedStringFromRTFFile:@"TextEdit Test Document"] intermediateAttributedStringWithAppKitAttributes];

    self.coreTextView.attributedString = [NSAttributedString attributedStringWithCoreTextAttributes:source];;
    self.appKitTextView.textStorage.attributedString = [NSAttributedString attributedStringWithAppKitAttributes:source];;
    NSLog(@"%@", self.coreTextView);
}

- (NSAttributedString *)readAttributedStringFromRTFFile:(NSString *)name {
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"rtf"];
    NSTextView *text = [[NSTextView alloc] init];
    [text readRTFDFromFile:path];
    return [text attributedString];
}

@end
