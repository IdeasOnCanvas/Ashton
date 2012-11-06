#import "NSAttributedString+Ashton.h"
#import "AshtonCoreText.h"
#if TARGET_OS_IPHONE
#else
#import "AshtonAppKit.h"
#endif

@implementation NSAttributedString (Ashton)

#if TARGET_OS_IPHONE
- (NSAttributedString *)intermediateAttributedStringWithUIKitAttributes {
    return nil;
}
+ (NSAttributedString *)attributedStringWithUIKitAttributes:(NSAttributedString *)inputWithIntermediateAttributes {
    return nil;
}
#else
- (NSAttributedString *)intermediateAttributedStringWithAppKitAttributes {
    return [[AshtonAppKit shared] intermediateRepresentationWithTargetRepresentation:self];
}
+ (NSAttributedString *)attributedStringWithAppKitAttributes:(NSAttributedString *)inputWithIntermediateAttributes {
    return [[AshtonAppKit shared] targetRepresentationWithIntermediateRepresentation:inputWithIntermediateAttributes];
}
#endif

- (NSAttributedString *)intermediateAttributedStringWithCoreTextAttributes {
    return [[AshtonCoreText shared] intermediateRepresentationWithTargetRepresentation:self];
}
+ (NSAttributedString *)attributedStringWithCoreTextAttributes:(NSAttributedString *)inputWithIntermediateAttributes {
    return [[AshtonCoreText shared] targetRepresentationWithIntermediateRepresentation:inputWithIntermediateAttributes];
}


@end
