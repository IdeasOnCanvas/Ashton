#import "NSAttributedString+MSAttributedStringSerialization.h"

#if TARGET_OS_IPHONE
#else
#import "MSASSAppKit.h"
#endif

@implementation NSAttributedString (MSAttributedStringSerialization)

#if TARGET_OS_IPHONE
- (NSAttributedString *)intermediateAttributedStringWithUIKitAttributes {
    return nil;
}
#else
- (NSAttributedString *)intermediateAttributedStringWithAppKitAttributes {
    return [[MSASSAppKit shared] intermediateRepresentationWithTargetRepresentation:self];
}
#endif

- (NSAttributedString *)intermediateAttributedStringWithCoreTextAttributes {
    return nil;
}

@end
