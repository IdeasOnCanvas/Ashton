#import "MSAttributedStringSerialization.h"

#if TARGET_OS_IPHONE
// In iOS 6 the attributed of an NSAttributedString have changed a lot, so we need to special case iOS5
// YES - iOS 6+
// NO - iOS 5
static BOOL NSASHasUIKitAdditions;
#endif

@implementation MSAttributedStringSerialization

+ (NSString *)HTMLStringWithAttributedString:(NSAttributedString *)attributedString {
    return nil;
}

+ (NSAttributedString *)attributedStringWithHTMLString:(NSString *)htmlString {
    return nil;
}

+ (void)initialize {
    if (self == [MSAttributedStringSerialization class]) {
#if TARGET_OS_IPHONE
        // determine if we're on iOS 6+
        NSASHasUIKitAdditions = ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options: NSNumericSearch] != NSOrderedAscending);
#endif
    }
}

@end
